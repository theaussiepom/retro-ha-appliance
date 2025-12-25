#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR=""
if [[ -d "$SCRIPT_DIR/lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/lib"
elif [[ -d "$SCRIPT_DIR/../lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/../lib"
else
  echo "enter-retro-mode [error]: unable to locate scripts/lib" >&2
  exit 1
fi

# shellcheck source=scripts/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=scripts/lib/common.sh
source "$LIB_DIR/common.sh"

kiosk_retropie_libdir() {
  echo "${KIOSK_RETROPIE_LIBDIR:-$(kiosk_retropie_path /usr/local/lib/kiosk-retropie)}"
}

kiosk_retropie_ledctl_path() {
  # Support both:
  # - installed layout: /usr/local/lib/kiosk-retropie/ledctl.sh
  # - repo layout: scripts/leds/ledctl.sh
  # Optional arg: script_dir override (defaults to this script's directory).
  local script_dir="${1:-$SCRIPT_DIR}"
  local candidate=""

  if [[ -n "${KIOSK_RETROPIE_LIBDIR:-}" ]]; then
    candidate="$KIOSK_RETROPIE_LIBDIR/ledctl.sh"
    if [[ -x "$candidate" ]]; then
      cover_path "enter-retro-mode:ledctl-libdir"
      echo "$candidate"
      return 0
    fi
  fi

  candidate="$script_dir/ledctl.sh"
  if [[ -x "$candidate" ]]; then
    cover_path "enter-retro-mode:ledctl-scriptdir"
    echo "$candidate"
    return 0
  fi

  candidate="$script_dir/../leds/ledctl.sh"
  if [[ -x "$candidate" ]]; then
    cover_path "enter-retro-mode:ledctl-scriptdir-leds"
    echo "$candidate"
    return 0
  fi

  # Fallback: installed default.
  cover_path "enter-retro-mode:ledctl-fallback"
  echo "$(kiosk_retropie_libdir)/ledctl.sh"
}

main() {
  export KIOSK_RETROPIE_LOG_PREFIX="enter-retro-mode"

  log "Switching to RetroPie mode"

  # Stop kiosk first to preserve single X ownership.
  svc_stop kiosk.service || true

  # RetroPie mode should force LEDs on.
  if [[ "${KIOSK_RETROPIE_SKIP_LEDCTL:-0}" == "1" ]]; then
    cover_path "enter-retro-mode:skip-ledctl"
  else
    local ledctl
    ledctl="$(kiosk_retropie_ledctl_path "$SCRIPT_DIR")"
    if [[ -x "$ledctl" ]]; then
      run_cmd "$ledctl" all on || true
    fi
  fi

  svc_start retro-mode.service
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
