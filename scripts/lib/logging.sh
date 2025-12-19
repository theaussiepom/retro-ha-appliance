#!/usr/bin/env bash
set -euo pipefail

# Logging helpers.

retro_ha_log_prefix() {
  # Allow callers to override the prefix for nicer logs.
  echo "${RETRO_HA_LOG_PREFIX:-retro-ha}"
}

log() {
  echo "$(retro_ha_log_prefix): $*" >&2
}

warn() {
  echo "$(retro_ha_log_prefix) [warn]: $*" >&2
}

die() {
  echo "$(retro_ha_log_prefix) [error]: $*" >&2
  exit 1
}
