# Configuration examples

This project is configured via `/etc/kiosk-retropie/config.env`.

These examples are intentionally verbose and scenario-driven. Copy one, then delete what you don’t need.

Notes:

- `KIOSK_RETROPIE_REPO_URL` + `KIOSK_RETROPIE_REPO_REF` are required for first-boot installs (cloud-init bootstrap).
- `KIOSK_URL` is required for kiosk mode.
- A line like `FOO=` means “set but empty” (often used to intentionally disable a feature or trigger a specific branch).

---

## 1) Minimal: kiosk + manual Retro

Use this when you only want the core appliance behavior and will switch modes manually.

```bash
# Required: bootstrap pin
KIOSK_RETROPIE_REPO_URL=https://github.com/theaussiepom/kiosk-retropie.git
KIOSK_RETROPIE_REPO_REF=v0.0.0

# Required: kiosk
KIOSK_URL=http://kiosk.local/

# Optional display tweaks
KIOSK_RETROPIE_SCREEN_ROTATION=normal
KIOSK_RETROPIE_X_VT=7
KIOSK_RETROPIE_RETRO_X_VT=8

# Keep optional integrations off
KIOSK_RETROPIE_LED_MQTT_ENABLED=0
KIOSK_RETROPIE_SCREEN_BRIGHTNESS_MQTT_ENABLED=0
KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=0
```

---

## 2) “Appliance” pinning: use a commit SHA

This maximizes repeatability: every Pi installs the same code.

```bash
KIOSK_RETROPIE_REPO_URL=https://github.com/theaussiepom/kiosk-retropie.git
KIOSK_RETROPIE_REPO_REF=863329f

KIOSK_URL=http://kiosk.local/
```

---

## 3) Rotate screen left + custom Chromium profile

Useful for portrait displays or odd mounting.

```bash
KIOSK_RETROPIE_REPO_URL=https://github.com/theaussiepom/kiosk-retropie.git
KIOSK_RETROPIE_REPO_REF=v0.0.0

KIOSK_URL=http://kiosk.local/

KIOSK_RETROPIE_SCREEN_ROTATION=left
KIOSK_RETROPIE_CHROMIUM_PROFILE_DIR=/var/lib/kiosk-retropie/chromium-profile
```

---

## 4) Controller switching: custom enter trigger key code

If your controller reports a different key code than the default (`315`).

```bash
KIOSK_RETROPIE_REPO_URL=https://github.com/theaussiepom/kiosk-retropie.git
KIOSK_RETROPIE_REPO_REF=v0.0.0

KIOSK_URL=http://kiosk.local/

KIOSK_RETROPIE_RETRO_ENTER_TRIGGER_CODE=314
KIOSK_RETROPIE_START_DEBOUNCE_SEC=0.5
```

---

## 5) ROM sync from NFS (read-only)

This syncs ROMs *into* local storage at boot. Gameplay does not run from NFS.

```bash
KIOSK_RETROPIE_REPO_URL=https://github.com/theaussiepom/kiosk-retropie.git
KIOSK_RETROPIE_REPO_REF=v0.0.0

KIOSK_URL=http://kiosk.local/

# Enable NFS ROM sync
NFS_SERVER=192.168.1.20
NFS_PATH=/export/retropie

# Optional: mount point and subdir
KIOSK_RETROPIE_NFS_MOUNT_POINT=/mnt/kiosk-retropie-roms
KIOSK_RETROPIE_NFS_ROMS_SUBDIR=roms

# Optional: only sync some systems
KIOSK_RETROPIE_ROMS_SYSTEMS=nes,snes,megadrive
KIOSK_RETROPIE_ROMS_EXCLUDE_SYSTEMS=

# Optional: mirror deletions (dangerous if you’re not expecting it)
KIOSK_RETROPIE_ROMS_SYNC_DELETE=0
```

---

## 6) Save backups to NFS (read-write, periodic)

This copies local saves/states to NFS on a timer and skips while Retro mode is active.

```bash
KIOSK_RETROPIE_REPO_URL=https://github.com/theaussiepom/kiosk-retropie.git
KIOSK_RETROPIE_REPO_REF=v0.0.0

KIOSK_URL=http://kiosk.local/

KIOSK_RETROPIE_SAVE_BACKUP_ENABLED=1

# Defaults to NFS_SERVER/NFS_PATH if unset
KIOSK_RETROPIE_SAVE_BACKUP_NFS_SERVER=192.168.1.20
KIOSK_RETROPIE_SAVE_BACKUP_NFS_PATH=/export/kiosk-retropie-backups

# Where to mount the backup share
KIOSK_RETROPIE_SAVE_BACKUP_DIR=/mnt/kiosk-retropie-backup

# Subdir on the mounted share
KIOSK_RETROPIE_SAVE_BACKUP_SUBDIR=pi-living-room

# Mirror deletions from local -> NFS
KIOSK_RETROPIE_SAVE_BACKUP_DELETE=0
```

---

## 7) MQTT client integration: MQTT LED control

Enables two-way LED sync: commands from an MQTT client control sysfs LEDs, and sysfs changes publish state.

```bash
KIOSK_RETROPIE_REPO_URL=https://github.com/theaussiepom/kiosk-retropie.git
KIOSK_RETROPIE_REPO_REF=v0.0.0

KIOSK_URL=http://kiosk.local/

KIOSK_RETROPIE_LED_MQTT_ENABLED=1
KIOSK_RETROPIE_MQTT_TOPIC_PREFIX=kiosk-retropie
KIOSK_RETROPIE_LED_MQTT_POLL_SEC=2

MQTT_HOST=192.168.1.50
MQTT_PORT=1883
MQTT_USERNAME=mqttuser
MQTT_PASSWORD=replace-me
MQTT_TLS=0
```

---

## 8) MQTT client integration: MQTT screen brightness

Publishes brightness state and accepts brightness percent commands.

```bash
KIOSK_RETROPIE_REPO_URL=https://github.com/theaussiepom/kiosk-retropie.git
KIOSK_RETROPIE_REPO_REF=v0.0.0

KIOSK_URL=http://kiosk.local/

KIOSK_RETROPIE_SCREEN_BRIGHTNESS_MQTT_ENABLED=1
KIOSK_RETROPIE_MQTT_TOPIC_PREFIX=kiosk-retropie
KIOSK_RETROPIE_SCREEN_BRIGHTNESS_MQTT_POLL_SEC=2

# Optional: pick a specific backlight device (otherwise auto-detect)
KIOSK_RETROPIE_BACKLIGHT_NAME=rpi_backlight

MQTT_HOST=192.168.1.50
MQTT_PORT=1883
MQTT_USERNAME=mqttuser
MQTT_PASSWORD=replace-me
MQTT_TLS=0
```

---

## 9) MQTT over TLS (typical pattern)

If your broker requires TLS, you’ll also need the broker CA available on the Pi.

```bash
KIOSK_RETROPIE_REPO_URL=https://github.com/theaussiepom/kiosk-retropie.git
KIOSK_RETROPIE_REPO_REF=v0.0.0

KIOSK_URL=http://kiosk.local/

KIOSK_RETROPIE_LED_MQTT_ENABLED=1
KIOSK_RETROPIE_SCREEN_BRIGHTNESS_MQTT_ENABLED=1
KIOSK_RETROPIE_MQTT_TOPIC_PREFIX=kiosk-retropie

MQTT_HOST=mqtt.example.internal
MQTT_PORT=8883
MQTT_USERNAME=mqttuser
MQTT_PASSWORD=replace-me
MQTT_TLS=1

# If the scripts support it in your setup, you may also mount a CA file and/or use mosquitto client options.
# (Broker TLS options vary; keep this file focused on env-vars the appliance consumes.)
```
