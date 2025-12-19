#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR=""
if [[ -d "$SCRIPT_DIR/lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/lib"
elif [[ -d "$SCRIPT_DIR/../lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/../lib"
else
  echo "save-backup [error]: unable to locate scripts/lib" >&2
  exit 1
fi

# shellcheck source=scripts/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=scripts/lib/common.sh
source "$LIB_DIR/common.sh"

main() {
  export RETRO_HA_LOG_PREFIX="save-backup"

  local enabled="${RETRO_HA_SAVE_BACKUP_ENABLED:-0}"
  if [[ "$enabled" != "1" ]]; then
    cover_path "save-backup:disabled"
    exit 0
  fi

  # Never write during gameplay.
  if systemctl is-active --quiet retro-mode.service; then
    cover_path "save-backup:retro-active"
    log "Retro mode active; skipping backup"
    exit 0
  fi

  local user="retropi"
  local saves_dir="${RETRO_HA_SAVES_DIR:-$(retro_ha_path /var/lib/retro-ha/retropie/saves)}"
  local states_dir="${RETRO_HA_STATES_DIR:-$(retro_ha_path /var/lib/retro-ha/retropie/states)}"
  local backup_root="${RETRO_HA_SAVE_BACKUP_DIR:-$(retro_ha_path /mnt/retro-ha-backup)}"
  local backup_subdir="${RETRO_HA_SAVE_BACKUP_SUBDIR:-retro-ha-saves}"
  local delete="${RETRO_HA_SAVE_BACKUP_DELETE:-0}"

  # Mount backup destination (rw) if configured.
  run_cmd "$SCRIPT_DIR/mount-nfs-backup.sh" || true

  if ! mountpoint -q "$backup_root"; then
    cover_path "save-backup:not-mounted"
    log "Backup mount not available at $backup_root; skipping"
    exit 0
  fi

  if ! command -v rsync > /dev/null 2>&1; then
    cover_path "save-backup:rsync-missing"
    log "rsync not installed; skipping"
    exit 0
  fi

  run_cmd mkdir -p "$backup_root/$backup_subdir"
  run_cmd chown -R "$user:$user" "$backup_root/$backup_subdir" || true

  local -a args
  args=(-a --info=stats2 --human-readable)
  if [[ "$delete" == "1" ]]; then
    cover_path "save-backup:delete-enabled"
    args+=(--delete)
  fi

  if [[ -d "$saves_dir" ]]; then
    cover_path "save-backup:backup-saves"
    log "Backing up saves: $saves_dir -> $backup_root/$backup_subdir/saves (delete=$delete)"
    run_cmd mkdir -p "$backup_root/$backup_subdir/saves"
    run_cmd rsync "${args[@]}" "$saves_dir/" "$backup_root/$backup_subdir/saves/" || true
  fi

  if [[ -d "$states_dir" ]]; then
    cover_path "save-backup:backup-states"
    log "Backing up states: $states_dir -> $backup_root/$backup_subdir/states (delete=$delete)"
    run_cmd mkdir -p "$backup_root/$backup_subdir/states"
    run_cmd rsync "${args[@]}" "$states_dir/" "$backup_root/$backup_subdir/states/" || true
  fi
}

if ! retro_ha_is_sourced; then
  main "$@"
fi
