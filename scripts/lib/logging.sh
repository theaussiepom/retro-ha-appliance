#!/usr/bin/env bash
set -euo pipefail

# Logging helpers.

kiosk_retropie__cover_path_raw() {
  [[ "${KIOSK_RETROPIE_PATH_COVERAGE:-0}" == "1" ]] || return 0

  local path_id="${1:-}"
  [[ -n "$path_id" ]] || return 0

  local path_file="${KIOSK_RETROPIE_PATHS_FILE:-${KIOSK_RETROPIE_CALLS_FILE_APPEND:-${KIOSK_RETROPIE_CALLS_FILE:-}}}"
  [[ -n "$path_file" ]] || return 0

  local dir
  dir="${path_file%/*}"
  if [[ -n "$dir" && "$dir" != "$path_file" ]]; then
    mkdir -p "$dir" 2> /dev/null || true
  fi
  printf 'PATH %s\n' "$path_id" >> "$path_file" 2> /dev/null || true
}

kiosk_retropie_log_prefix() {
  # Allow callers to override the prefix for nicer logs.
  if [[ -n "${KIOSK_RETROPIE_LOG_PREFIX:-}" ]]; then
    kiosk_retropie__cover_path_raw "lib-logging:prefix-override"
  else
    kiosk_retropie__cover_path_raw "lib-logging:prefix-default"
  fi
  echo "${KIOSK_RETROPIE_LOG_PREFIX:-kiosk-retropie}"
}

log() {
  kiosk_retropie__cover_path_raw "lib-logging:log"
  echo "$(kiosk_retropie_log_prefix): $*" >&2
}

warn() {
  kiosk_retropie__cover_path_raw "lib-logging:warn"
  echo "$(kiosk_retropie_log_prefix) [warn]: $*" >&2
}

die() {
  kiosk_retropie__cover_path_raw "lib-logging:die"
  echo "$(kiosk_retropie_log_prefix) [error]: $*" >&2
  exit 1
}
