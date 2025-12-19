#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR=""
if [[ -d "$SCRIPT_DIR/lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/lib"
elif [[ -d "$SCRIPT_DIR/../lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/../lib"
else
  echo "healthcheck [error]: unable to locate scripts/lib" >&2
  exit 1
fi

# shellcheck source=scripts/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=scripts/lib/common.sh
source "$LIB_DIR/common.sh"

is_active() {
  systemctl is-active --quiet "$1"
}

main() {
  export RETRO_HA_LOG_PREFIX="healthcheck"

  # Fail-open principle: if we're not in HA mode or Retro mode, enter Retro mode.
  # This is intentionally simple and avoids network/URL probing.
  if is_active ha-kiosk.service; then
    log "HA kiosk active"
    exit 0
  fi
  if is_active retro-mode.service; then
    log "Retro mode active"
    exit 0
  fi

  log "No active mode detected; failing over to Retro mode"
  local enter
  if [[ -n "${RETRO_HA_LIBDIR:-}" && -x "$RETRO_HA_LIBDIR/enter-retro-mode.sh" ]]; then
    enter="$RETRO_HA_LIBDIR/enter-retro-mode.sh"
  elif [[ -x "$SCRIPT_DIR/enter-retro-mode.sh" ]]; then
    enter="$SCRIPT_DIR/enter-retro-mode.sh"
  elif [[ -x "$SCRIPT_DIR/mode/enter-retro-mode.sh" ]]; then
    enter="$SCRIPT_DIR/mode/enter-retro-mode.sh"
  else
    enter="$(retro_ha_path /usr/local/lib/retro-ha)/enter-retro-mode.sh"
  fi

  run_cmd "$enter" || true
}

if ! retro_ha_is_sourced; then
  main "$@"
fi
