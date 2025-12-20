# Architecture

This document describes how retro-ha-appliance is structured and how its components interact at runtime.

## Goals

- Provide two exclusive modes on one Raspberry Pi:
  - Home Assistant kiosk (default)
  - RetroPie mode (on-demand)
- Enforce single ownership of X at all times.
- Fail open: if kiosk mode is unhealthy, RetroPie remains reachable.
- Keep gameplay independent from network storage.

## Non-goals

- A full desktop environment.
- Running both modes simultaneously.
- Running ROMs directly from NFS.

## High-level component map

Runtime is orchestrated by systemd. Scripts are installed under `/usr/local/lib/retro-ha` and
configuration is loaded from `/etc/retro-ha/config.env`.

### Systemd units

Install-time:

- `retro-ha-install.service`: one-time installer (first boot; retried until it succeeds).

Mode and switching:

- `ha-kiosk.service`: HA kiosk mode, Xorg on VT7 by default.
- `retro-mode.service`: Retro mode, Xorg on VT8 by default.
- `ha-mode-controller-listener.service`: listens for controller Start button while HA mode is active.
- `emergency-retro-launch.service`: always-on listener on a TTY for emergency Retro launch.
- `retro-ha-failover.service`: invoked by `ha-kiosk.service` OnFailure to switch into Retro.

Periodic maintenance:

- `boot-sync.service`: optional boot-time ROM sync from NFS.
- `healthcheck.service` + `healthcheck.timer`: periodic fail-open check.
- `save-backup.service` + `save-backup.timer`: optional backup of local saves/states to NFS.

Optional integration:

- `retro-ha-led-mqtt.service`: optional MQTT-driven LED control bridge.

### Installed layout

- `/etc/retro-ha/config.env`: runtime configuration.
- `/usr/local/lib/retro-ha/*.sh`: installed scripts.
- `/usr/local/bin/retro-ha-led-mqtt.sh`: MQTT LED bridge entrypoint.
- `/var/lib/retro-ha/`: appliance state and data (ROMs, saves, marker file).

## Boot and installation flow

The first boot flow is designed to be idempotent.

1. A cloud-init user-data file writes `/etc/retro-ha/config.env` and installs
   `/etc/systemd/system/retro-ha-install.service` and `/usr/local/lib/retro-ha/bootstrap.sh`.
2. `retro-ha-install.service` runs after `network-online.target`.
3. `bootstrap.sh` checks for `/var/lib/retro-ha/installed`:
   - If present, it exits successfully.
   - Otherwise it clones/fetches the repo (pinned by `RETRO_HA_REPO_URL` + `RETRO_HA_REPO_REF`) and execs
     `scripts/install.sh` from that checkout.
4. `scripts/install.sh` installs packages and copies scripts/units into their installed locations,
   enables the required services/timers, then writes the installed marker.

Re-running install without reflashing is supported by deleting the marker file and restarting the unit.

## Mode ownership and display

Both modes start X explicitly via `xinit` and run on fixed VTs:

- HA kiosk: VT7 (`RETRO_HA_X_VT`, default `7`)
- Retro mode: VT8 (`RETRO_HA_RETRO_X_VT`, default `8`)

systemd enforces exclusivity:

- `ha-kiosk.service` declares `Conflicts=retro-mode.service`.
- `retro-mode.service` declares `Conflicts=ha-kiosk.service`.

Each service is configured to run with a logind session (TTY + `PAMName=login`) so rootless Xorg can
acquire the seat.

## Mode switching

### Manual switching

- Switch to Retro: `systemctl start retro-mode.service`
- Switch to HA: `systemctl start ha-kiosk.service`

Because of `Conflicts=`, starting one mode will stop the other.

### Controller-driven switching

Two Python-based listeners read evdev events from `/dev/input/by-id/*event-joystick`:

- `ha-mode-controller-listener.service`:
  - Requires HA kiosk to be active.
  - On Start button press, starts `retro-mode.service`.
- `emergency-retro-launch.service`:
  - Runs outside X and stays enabled.
  - On Start button press, stops HA and starts Retro.

The Start button key code defaults to `315` (`BTN_START`) and can be overridden.

## Fail-open behavior

Fail-open is implemented in two layers:

1. `ha-kiosk.service` uses `OnFailure=retro-ha-failover.service`.
   If kiosk fails repeatedly (StartLimitBurst), systemd runs the failover service.
2. `healthcheck.timer` periodically runs `healthcheck.sh`.
   If neither `ha-kiosk.service` nor `retro-mode.service` is active, it runs `enter-retro-mode.sh`.

## Storage model

The storage design separates gameplay data from network availability.

### ROMs

- ROMs live locally (default: `/var/lib/retro-ha/retropie/roms`).
- If NFS is configured, `boot-sync.service` attempts to mount a share read-only and sync ROMs into the
  local directory.
- If NFS is down, ROM sync is skipped and the device continues to work with the last local ROM set.

### Saves and states

- Saves and savestates are always local:
  - `RETRO_HA_SAVES_DIR` (default: `/var/lib/retro-ha/retropie/saves`)
  - `RETRO_HA_STATES_DIR` (default: `/var/lib/retro-ha/retropie/states`)
- Optional backup to NFS is implemented as a periodic rsync job and is disabled by default.
- Backup explicitly skips while `retro-mode.service` is active.

## LED behavior and MQTT bridge

LED control is done by writing to sysfs via `ledctl.sh`.

If enabled, `retro-ha-led-mqtt.service` subscribes to MQTT topics (default prefix `retro-ha`) and calls
`ledctl.sh` to toggle ACT/PWR LEDs. It also publishes retained state topics for Home Assistant UI.

## Observability and debugging

- Journald is the primary log sink.
- Most issues can be diagnosed with:

```bash
systemctl status ha-kiosk.service retro-mode.service retro-ha-install.service
journalctl -u ha-kiosk.service -b --no-pager
```

See the troubleshooting guide for symptom-based diagnosis.

## Security notes (practical)

- This project assumes a trusted LAN. It does not expose a network API by default.
- MQTT credentials (if used) are stored in `/etc/retro-ha/config.env`; treat that file as sensitive.
- Scripts are installed under `/usr/local` and run under a dedicated `retropi` user for kiosk/retro
  services.
