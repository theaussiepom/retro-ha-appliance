#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-support/load"
load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-assert/load"

setup() {
  export KIOSK_RETROPIE_ROOT
  KIOSK_RETROPIE_ROOT="$(mktemp -d)"

  export KIOSK_RETROPIE_CALLS_FILE
  KIOSK_RETROPIE_CALLS_FILE="${KIOSK_RETROPIE_ROOT}/calls.txt"
  export KIOSK_RETROPIE_CALLS_FILE_APPEND=""

  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/common.sh"
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/path.sh"
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/retropie/configure-retropie-storage.sh"

  export KIOSK_RETROPIE_DRY_RUN=0
}

test_teardown() {
  rm -rf "${KIOSK_RETROPIE_ROOT}" || true
}

@test "ensure_kv_line appends key when missing" {
  local f
  f="${KIOSK_RETROPIE_ROOT}/retroarch.cfg"

  printf 'foo = "bar"\n' >"$f"

  ensure_kv_line "$f" "savefile_directory" "/saves"

  run grep -E '^savefile_directory[[:space:]]*=' "$f"
  assert_success
  assert_output 'savefile_directory = "/saves"'
}

@test "ensure_kv_line replaces existing key" {
  local f
  f="${KIOSK_RETROPIE_ROOT}/retroarch.cfg"

  printf 'savefile_directory = "/old"\nother = "x"\n' >"$f"

  ensure_kv_line "$f" "savefile_directory" "/new"

  run cat "$f"
  assert_success
  assert_output $'savefile_directory = "/new"\nother = "x"'
}

@test "ensure_kv_line dry-run records write_kv and does not modify file" {
  local f
  f="${KIOSK_RETROPIE_ROOT}/retroarch.cfg"

  printf 'savefile_directory = "/old"\n' >"$f"

  KIOSK_RETROPIE_DRY_RUN=1
  ensure_kv_line "$f" "savefile_directory" "/new"

  run cat "$f"
  assert_success
  assert_output 'savefile_directory = "/old"'

  run cat "$KIOSK_RETROPIE_CALLS_FILE"
  assert_success
  assert_output --partial "write_kv ${f} savefile_directory"
}
