#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-support/load"
load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-assert/load"

setup() {
  export KIOSK_RETROPIE_ROOT
  KIOSK_RETROPIE_ROOT="$(mktemp -d)"

  export KIOSK_RETROPIE_CALLS_FILE
  KIOSK_RETROPIE_CALLS_FILE="${KIOSK_RETROPIE_ROOT}/calls.txt"

  local old_path="$PATH"
  export _OLD_PATH="$old_path"
  PATH="${KIOSK_RETROPIE_REPO_ROOT}/tests/stubs:$PATH"

  # Source script under test (guarded main).
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/bootstrap.sh"
}

test_teardown() {
  PATH="${_OLD_PATH}"
  rm -rf "${KIOSK_RETROPIE_ROOT}" || true
}

@test "network_ok succeeds when getent and curl succeed" {
  export GETENT_HOSTS_EXIT_CODE=0
  export CURL_EXIT_CODE=0

  run network_ok
  assert_success

  run cat "$KIOSK_RETROPIE_CALLS_FILE"
  assert_success
  assert_output --partial "getent"
  assert_output --partial "github.com"
  assert_output --partial "curl"
  assert_output --partial "https://github.com"
}

@test "network_ok fails fast when getent fails (curl not called)" {
  export GETENT_HOSTS_EXIT_CODE=2
  export CURL_EXIT_CODE=0

  run network_ok
  assert_failure

  run cat "$KIOSK_RETROPIE_CALLS_FILE"
  assert_success
  assert_output --partial "getent"
  assert_output --partial "github.com"
  refute_output --partial "curl"
}

@test "network_ok fails when curl fails" {
  export GETENT_HOSTS_EXIT_CODE=0
  export CURL_EXIT_CODE=22

  run network_ok
  assert_failure

  run cat "$KIOSK_RETROPIE_CALLS_FILE"
  assert_success
  assert_output --partial "getent"
  assert_output --partial "github.com"
  assert_output --partial "curl"
  assert_output --partial "https://github.com"
}
