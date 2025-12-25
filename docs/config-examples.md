# Configuration examples

This project is configured via `/etc/kiosk-retropie/config.env`.

This repo provides two canonical examples:

1) Manual install (config file only): [examples/config.env.example](../examples/config.env.example)
2) Flashing install (Pi Imager / cloud-init): [examples/pi-imager/user-data.example.yml](../examples/pi-imager/user-data.example.yml)

Notes:

- A line like `FOO=` means “set but empty”. This is often used to intentionally disable a feature or to force a
  script down a specific error-handling path.
- Some variables are “obvious plumbing” (e.g. `NFS_SERVER`), while others are application-specific (e.g.
  `KIOSK_CHROMIUM_PROFILE_DIR`). The examples include inline comments for the application-specific ones.

## Manual install example

The manual install path assumes you can SSH in and run the installer yourself.

Mandatory variables for this scenario:

- `KIOSK_URL`

Optional features (NFS ROM sync, save backups, MQTT) are fully commented out in the example so you can enable
them intentionally.

## Flashing / cloud-init example

The flashing path relies on cloud-init to write the config file and run a one-time installer service.

Mandatory variables for this scenario:

- `KIOSK_RETROPIE_REPO_URL`
- `KIOSK_RETROPIE_REPO_REF`
- `KIOSK_URL`

Optional options are commented out in the config payload embedded in the user-data.
