#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR=""
if [[ -d "$SCRIPT_DIR/lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/lib"
elif [[ -d "$SCRIPT_DIR/../lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/../lib"
else
  echo "enter-kiosk-mode [error]: unable to locate scripts/lib" >&2
  exit 1
fi

# shellcheck source=scripts/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=scripts/lib/common.sh
source "$LIB_DIR/common.sh"

main() {
  export KIOSK_RETROPIE_LOG_PREFIX="enter-kiosk-mode"

  log "Switching to kiosk mode"

  # Stop RetroPie mode first to preserve single X ownership.
  cover_path "enter-kiosk-mode:stop-retro"
  svc_stop retro-mode.service || true

  # Start kiosk.
  cover_path "enter-kiosk-mode:start-kiosk"
  svc_start kiosk.service
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
