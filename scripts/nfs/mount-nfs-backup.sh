#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR=""
if [[ -d "$SCRIPT_DIR/lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/lib"
elif [[ -d "$SCRIPT_DIR/../lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/../lib"
else
  echo "mount-nfs-backup [error]: unable to locate scripts/lib" >&2
  exit 1
fi

# shellcheck source=scripts/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=scripts/lib/common.sh
source "$LIB_DIR/common.sh"

main() {
  export KIOSK_RETROPIE_LOG_PREFIX="mount-nfs-backup"

  local enabled="${RETROPIE_SAVE_BACKUP_ENABLED:-${KIOSK_RETROPIE_SAVE_BACKUP_ENABLED:-0}}"
  if [[ "$enabled" != "1" ]]; then
    cover_path "mount-nfs-backup:disabled"
    exit 0
  fi

  local server="${NFS_SERVER:-}"
  local export_path="${NFS_SAVE_BACKUP_PATH:-${RETROPIE_SAVE_BACKUP_NFS_PATH:-${KIOSK_RETROPIE_SAVE_BACKUP_NFS_PATH:-${NFS_PATH:-${NFS_ROMS_PATH:-}}}}}"
  local mount_point="${RETROPIE_SAVE_BACKUP_DIR:-${KIOSK_RETROPIE_SAVE_BACKUP_DIR:-$(kiosk_retropie_path /mnt/kiosk-retropie-backup)}}"
  local mount_opts="${RETROPIE_SAVE_BACKUP_NFS_MOUNT_OPTIONS:-${KIOSK_RETROPIE_SAVE_BACKUP_NFS_MOUNT_OPTIONS:-rw}}"

  if [[ -n "${RETROPIE_SAVE_BACKUP_NFS_SERVER:-${KIOSK_RETROPIE_SAVE_BACKUP_NFS_SERVER:-}}" ]]; then
    cover_path "mount-nfs-backup:legacy-server-ignored"
    log "KIOSK_RETROPIE_SAVE_BACKUP_NFS_SERVER is deprecated and ignored; using NFS_SERVER"
  fi
  if [[ -n "${RETROPIE_SAVE_BACKUP_NFS_PATH:-${KIOSK_RETROPIE_SAVE_BACKUP_NFS_PATH:-}}" && -z "${NFS_SAVE_BACKUP_PATH:-}" ]]; then
    cover_path "mount-nfs-backup:legacy-path"
    log "Using legacy KIOSK_RETROPIE_SAVE_BACKUP_NFS_PATH; prefer NFS_SAVE_BACKUP_PATH"
  fi

  if [[ -z "$server" || -z "$export_path" ]]; then
    cover_path "mount-nfs-backup:not-configured"
    log "Backup NFS not configured (set NFS_SERVER and NFS_SAVE_BACKUP_PATH); skipping"
    exit 0
  fi

  run_cmd mkdir -p "$mount_point"
  if mountpoint -q "$mount_point"; then
    cover_path "mount-nfs-backup:already-mounted"
    exit 0
  fi

  log "Mounting ${server}:${export_path} -> ${mount_point} (opts: ${mount_opts})"
  cover_path "mount-nfs-backup:mount-attempt"
  if ! run_cmd mount -t nfs -o "$mount_opts" "${server}:${export_path}" "$mount_point"; then
    cover_path "mount-nfs-backup:mount-failed"
    log "Mount failed; continuing without backup"
    exit 0
  fi

  cover_path "mount-nfs-backup:mount-success"
}

if ! kiosk_retropie_is_sourced; then
  main "$@"
fi
