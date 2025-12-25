#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

KIOSK_RETROPIE_REPO_ROOT="${KIOSK_RETROPIE_REPO_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"

load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-support/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-assert/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/helpers/common"

setup() {
  setup_test_root
}

test_teardown() {
  teardown_test_root
}

@test "branch coverage: common.sh + logging.sh helper branches" {
  # common.sh branches
  source "$KIOSK_RETROPIE_REPO_ROOT/scripts/lib/common.sh"

  # kiosk_retropie_is_sourced branches: mirror the unit test pattern.
  local script
  script="$TEST_ROOT/sourced-check.sh"
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

  run bash "$script"
  assert_success

  run bash -c "source '$script'"
  assert_success

  # root branches
  unset KIOSK_RETROPIE_ROOT
  run kiosk_retropie_root
  assert_success

  export KIOSK_RETROPIE_ROOT="$TEST_ROOT/"
  run kiosk_retropie_root
  assert_success

  # path branches
  export KIOSK_RETROPIE_ROOT="$TEST_ROOT"
  run kiosk_retropie_path "relative"
  assert_success
  export KIOSK_RETROPIE_ROOT="/"
  run kiosk_retropie_path "/etc/hosts"
  assert_success
  export KIOSK_RETROPIE_ROOT="$TEST_ROOT"
  run kiosk_retropie_path "/etc/hosts"
  assert_success

  # dirname branches
  run kiosk_retropie_dirname ""
  assert_success
  run kiosk_retropie_dirname "foo"
  assert_success
  run kiosk_retropie_dirname "foo/bar"
  assert_success
  run kiosk_retropie_dirname "/foo"
  assert_success
  run kiosk_retropie_dirname "foo/bar/"
  assert_success

  # record_call branches
  export KIOSK_RETROPIE_CALLS_FILE="$TEST_ROOT/calls-primary.log"
  export KIOSK_RETROPIE_CALLS_FILE_APPEND="$TEST_ROOT/calls-append.log"
  record_call "hello"

  unset KIOSK_RETROPIE_CALLS_FILE
  record_call "no-primary"

  export KIOSK_RETROPIE_CALLS_FILE="$TEST_ROOT/calls-primary.log"
  unset KIOSK_RETROPIE_CALLS_FILE_APPEND
  record_call "no-append"

  # run_cmd branches
  export KIOSK_RETROPIE_DRY_RUN=1
  run run_cmd echo hi
  assert_success

  export KIOSK_RETROPIE_DRY_RUN=0
  run run_cmd echo hi
  assert_success

  # realpath
  run kiosk_retropie_realpath_m "a/../b"
  assert_success

  # logging.sh branches
  # shellcheck source=../../scripts/lib/logging.sh
  source "$KIOSK_RETROPIE_REPO_ROOT/scripts/lib/logging.sh"

  unset KIOSK_RETROPIE_LOG_PREFIX
  run kiosk_retropie_log_prefix
  assert_success

  export KIOSK_RETROPIE_LOG_PREFIX="x"
  run kiosk_retropie_log_prefix
  assert_success

  run log "hello"
  assert_success

  run warn "hello"
  assert_success

  run bash -c '
    set -euo pipefail
    source "$1"
    export KIOSK_RETROPIE_PATH_COVERAGE=1
    export KIOSK_RETROPIE_CALLS_FILE_APPEND="$2"
    die "boom"
  ' bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/lib/logging.sh" "$TEST_ROOT/path-log.log"
  assert_failure
}
