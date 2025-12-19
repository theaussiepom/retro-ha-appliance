#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../lib/common.sh" ]]; then
  # shellcheck source=scripts/lib/common.sh
  source "$SCRIPT_DIR/../lib/common.sh"
  cover_path "leds-on:run"
fi

"$(dirname "$0")/ledctl.sh" all on
