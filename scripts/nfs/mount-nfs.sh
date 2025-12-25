#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR=""
if [[ -d "$SCRIPT_DIR/lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/lib"
elif [[ -d "$SCRIPT_DIR/../lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/../lib"
else
  echo "mount-nfs [error]: unable to locate scripts/lib" >&2
  exit 1
fi

# shellcheck source=scripts/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=scripts/lib/common.sh
source "$LIB_DIR/common.sh"

main() {
  export KIOSK_RETROPIE_LOG_PREFIX="mount-nfs"

  local server="${NFS_SERVER:-}"
  local export_path="${NFS_PATH:-}"
  local mount_point="${KIOSK_RETROPIE_NFS_MOUNT_POINT:-$(kiosk_retropie_path /mnt/kiosk-retropie-roms)}"
  local mount_opts="${KIOSK_RETROPIE_NFS_MOUNT_OPTIONS:-ro}"

  if [[ -z "$server" || -z "$export_path" ]]; then
    cover_path "mount-nfs:not-configured"
    log "NFS not configured (set NFS_SERVER and NFS_PATH); skipping"
    exit 0
  fi

  require_cmd mount
  require_cmd mountpoint

  run_cmd mkdir -p "$mount_point"

  if mountpoint -q "$mount_point"; then
    cover_path "mount-nfs:already-mounted"
    log "Already mounted at $mount_point"
    exit 0
  fi

  log "Mounting ${server}:${export_path} -> ${mount_point} (opts: ${mount_opts})"

  # Fail-open semantics: if NFS is unavailable, do not fail the appliance.
  cover_path "mount-nfs:mount-attempt"
  if ! run_cmd mount -t nfs -o "$mount_opts" "${server}:${export_path}" "$mount_point"; then
    cover_path "mount-nfs:mount-failed"
    log "Mount failed; continuing without NFS"
    exit 0
  fi

  cover_path "mount-nfs:mount-success"

  log "Mounted successfully"
}

if ! kiosk_retropie_is_sourced; then
  main "$@"
fi
