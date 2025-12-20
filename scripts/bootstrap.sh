#!/usr/bin/env bash
set -euo pipefail

# Bootstrap entrypoint invoked by systemd on first boot.
#
# Responsibilities:
# - Wait for network (systemd retries this unit on failure)
# - Fetch/clone the repo at a pinned ref
# - Run scripts/install.sh from that checkout

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR=""
if [[ -d "$SCRIPT_DIR/lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/lib"
elif [[ -d "$SCRIPT_DIR/../lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/../lib"
else
  echo "retro-ha bootstrap [error]: unable to locate scripts/lib" >&2
  exit 1
fi

# shellcheck source=scripts/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=scripts/lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=scripts/lib/config.sh
source "$LIB_DIR/config.sh"

network_ok() {
  # DNS + HTTPS reachability (kept simple).
  getent hosts github.com > /dev/null 2>&1 && curl -fsS https://github.com > /dev/null 2>&1
}

main() {
  export RETRO_HA_LOG_PREFIX="retro-ha bootstrap"

  local installed_marker
  installed_marker="${RETRO_HA_INSTALLED_MARKER:-$(retro_ha_path /var/lib/retro-ha/installed)}"

  if [[ -f "$installed_marker" ]]; then
    log "Marker present; nothing to do."
    exit 0
  fi

  load_config_env

  require_cmd curl
  require_cmd git

  if ! network_ok; then
    die "Network not ready yet"
  fi

  local repo_url="${RETRO_HA_REPO_URL:-}"
  local repo_ref="${RETRO_HA_REPO_REF:-}"

  [[ -n "$repo_url" ]] || die "RETRO_HA_REPO_URL is required (set in /etc/retro-ha/config.env)"
  [[ -n "$repo_ref" ]] || die "RETRO_HA_REPO_REF is required (branch/tag/commit)"

  local checkout_dir="${RETRO_HA_CHECKOUT_DIR:-$(retro_ha_path /opt/retro-ha-appliance)}"

  if [[ ! -d "$checkout_dir/.git" ]]; then
    log "Cloning $repo_url -> $checkout_dir"
    run_cmd rm -rf "$checkout_dir"
    run_cmd git clone --no-checkout "$repo_url" "$checkout_dir"
  fi

  log "Fetching ref $repo_ref"
  run_cmd git -C "$checkout_dir" fetch --depth 1 origin "$repo_ref"
  run_cmd git -C "$checkout_dir" checkout -f FETCH_HEAD

  if [[ ! -x "$checkout_dir/scripts/install.sh" ]]; then
    die "Installer not found or not executable: $checkout_dir/scripts/install.sh"
  fi

  log "Running installer"
  if [[ "${RETRO_HA_DRY_RUN:-0}" == "1" ]]; then
    record_call "exec $checkout_dir/scripts/install.sh"
    exit 0
  fi

  exec "$checkout_dir/scripts/install.sh"
}

if ! retro_ha_is_sourced; then
  main "$@"
fi
