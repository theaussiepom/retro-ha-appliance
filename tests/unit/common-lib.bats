#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-support/load"
load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-assert/load"

setup() {
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/common.sh"

  export KIOSK_RETROPIE_ROOT
  KIOSK_RETROPIE_ROOT="$(mktemp -d)"

  export KIOSK_RETROPIE_CALLS_FILE
  KIOSK_RETROPIE_CALLS_FILE="${KIOSK_RETROPIE_ROOT}/calls/log.txt"

  export KIOSK_RETROPIE_CALLS_FILE_APPEND
  KIOSK_RETROPIE_CALLS_FILE_APPEND="${KIOSK_RETROPIE_ROOT}/calls/all.txt"
  export KIOSK_RETROPIE_DRY_RUN=0
}

test_teardown() {
  rm -rf "${KIOSK_RETROPIE_ROOT}" || true
}

@test "kiosk_retropie_root normalizes trailing slash" {
  KIOSK_RETROPIE_ROOT="/tmp/kiosk-retropie/"
  run kiosk_retropie_root
  assert_success
  assert_output "/tmp/kiosk-retropie"
}

@test "kiosk_retropie_path prefixes absolute paths with KIOSK_RETROPIE_ROOT" {
  KIOSK_RETROPIE_ROOT="/tmp/kiosk-retropie"
  run kiosk_retropie_path "/etc/foo"
  assert_success
  assert_output "/tmp/kiosk-retropie/etc/foo"
}

@test "kiosk_retropie_path leaves absolute paths unchanged when KIOSK_RETROPIE_ROOT is /" {
  KIOSK_RETROPIE_ROOT="/"
  run kiosk_retropie_path "/etc/foo"
  assert_success
  assert_output "/etc/foo"
}

@test "kiosk_retropie_path leaves relative paths unchanged" {
  KIOSK_RETROPIE_ROOT="/tmp/kiosk-retropie"
  run kiosk_retropie_path "relative/path"
  assert_success
  assert_output "relative/path"
}

@test "kiosk_retropie_dirname matches basic dirname cases" {
  run kiosk_retropie_dirname ""
  assert_success
  assert_output "."

  run kiosk_retropie_dirname "foo"
  assert_success
  assert_output "."

  run kiosk_retropie_dirname "foo/bar"
  assert_success
  assert_output "foo"

  run kiosk_retropie_dirname "/foo"
  assert_success
  assert_output "/"

  run kiosk_retropie_dirname "/foo/bar/"
  assert_success
  assert_output "/foo"

  run kiosk_retropie_dirname "/"
  assert_success
  assert_output "/"
}

@test "record_call writes to calls file and append file" {
  run record_call "hello" "world"
  assert_success

  [ -f "$KIOSK_RETROPIE_CALLS_FILE" ]
  [ -f "$KIOSK_RETROPIE_CALLS_FILE_APPEND" ]

  run cat "$KIOSK_RETROPIE_CALLS_FILE"
  assert_success
  assert_output "hello world"

  run cat "$KIOSK_RETROPIE_CALLS_FILE_APPEND"
  assert_success
  assert_output "hello world"
}

@test "cover_path records PATH entries when enabled" {
  export KIOSK_RETROPIE_PATH_COVERAGE=1

  run cover_path "FOO"
  assert_success

  run cat "$KIOSK_RETROPIE_CALLS_FILE"
  assert_success
  assert_output "PATH FOO"
}

@test "run_cmd records calls in dry-run mode and returns success" {
  KIOSK_RETROPIE_DRY_RUN=1

  run run_cmd false
  assert_success

  run cat "$KIOSK_RETROPIE_CALLS_FILE"
  assert_success
  assert_output "false"
}

@test "kiosk_retropie_is_sourced detects sourced top-level script" {
  local script
  script="${KIOSK_RETROPIE_ROOT}/sourced-check.sh"

  cat >"$script" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/common.sh"

if kiosk_retropie_is_sourced; then
  echo sourced
else
  echo executed
fi
SH
  chmod +x "$script"

  # Executed normally: should be 'executed'
  run bash "$script"
  assert_success
  assert_output "executed"

  # Sourced into an interactive shell: should be 'sourced'
  run bash -c "source '$script'"
  assert_success
  assert_output "sourced"
}
