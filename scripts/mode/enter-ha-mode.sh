#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR=""
if [[ -d "$SCRIPT_DIR/lib" ]]; then
	LIB_DIR="$SCRIPT_DIR/lib"
elif [[ -d "$SCRIPT_DIR/../lib" ]]; then
	LIB_DIR="$SCRIPT_DIR/../lib"
else
	echo "enter-ha-mode [error]: unable to locate scripts/lib" >&2
	exit 1
fi

# shellcheck source=scripts/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=scripts/lib/common.sh
source "$LIB_DIR/common.sh"

main() {
	export RETRO_HA_LOG_PREFIX="enter-ha-mode"

	log "Switching to HA kiosk mode"

	# Stop RetroPie mode first to preserve single X ownership.
	svc_stop retro-mode.service || true

	# Start HA kiosk.
	svc_start ha-kiosk.service
}

if ! retro_ha_is_sourced; then
	main "$@"
fi
