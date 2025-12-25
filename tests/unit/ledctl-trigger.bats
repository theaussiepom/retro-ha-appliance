#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-support/load"
load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-assert/load"

setup() {
  export KIOSK_RETROPIE_ROOT
  KIOSK_RETROPIE_ROOT="$(mktemp -d)"

  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/leds/ledctl.sh"
}

test_teardown() {
  rm -rf "${KIOSK_RETROPIE_ROOT}" || true
}

@test "trigger_supported matches desired trigger even when bracketed" {
  local f
  f="${KIOSK_RETROPIE_ROOT}/trigger"
  printf 'none [mmc0] timer heartbeat\n' >"$f"

  run trigger_supported "$f" "mmc0"
  assert_success
}

@test "trigger_supported rejects partial-word matches" {
  local f
  f="${KIOSK_RETROPIE_ROOT}/trigger"
  printf 'none [mmc0] timer\n' >"$f"

  run trigger_supported "$f" "mmc"
  assert_failure
}

@test "trigger_supported fails when file missing" {
  run trigger_supported "${KIOSK_RETROPIE_ROOT}/does-not-exist" "mmc0"
  assert_failure
}
