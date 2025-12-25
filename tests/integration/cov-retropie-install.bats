#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

KIOSK_RETROPIE_REPO_ROOT="${KIOSK_RETROPIE_REPO_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"

load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-support/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-assert/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/helpers/common"

setup() {
  setup_test_root
  export KIOSK_RETROPIE_DRY_RUN=1
  export KIOSK_RETROPIE_ALLOW_NON_ROOT=1

  # Ensure retropi home resolves under KIOSK_RETROPIE_ROOT.
  export GETENT_PASSWD_RETROPI_LINE="retropi:x:1000:1000::${TEST_ROOT}/home/retropi:/bin/bash"
  mkdir -p "$TEST_ROOT/home/retropi"
}

teardown() {
  teardown_test_root
}

@test "install-retropie fails when user missing" {
  export KIOSK_RETROPIE_ALLOW_NON_ROOT=1
  make_isolated_path_with_stubs dirname git sudo getent
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/retropie/install-retropie.sh"
  assert_failure
  assert_file_contains "$TEST_ROOT/calls.log" "PATH retropie-install:user-missing"
}

@test "install-retropie fails when git missing" {
  make_isolated_path_with_stubs dirname sudo getent id
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/retropie/install-retropie.sh"
  assert_failure
  assert_file_contains "$TEST_ROOT/calls.log" "PATH retropie-install:git-missing"
}

@test "install-retropie fails when sudo missing" {
  make_isolated_path_with_stubs dirname git getent id
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/retropie/install-retropie.sh"
  assert_failure
  assert_file_contains "$TEST_ROOT/calls.log" "PATH retropie-install:sudo-missing"
}

@test "install-retropie fails when home dir missing" {
  export GETENT_PASSWD_RETROPI_LINE="retropi:x:1000:1000::::/bin/bash"
  make_isolated_path_with_stubs dirname git sudo getent id
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/retropie/install-retropie.sh"
  assert_failure
  assert_file_contains "$TEST_ROOT/calls.log" "PATH retropie-install:home-missing"
}

@test "install-retropie clone path in dry-run" {
  make_isolated_path_with_stubs dirname git sudo getent id
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/retropie/install-retropie.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH retropie-install:clone"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH retropie-install:dry-run"
}

@test "install-retropie update path in dry-run" {
  mkdir -p "$TEST_ROOT/home/retropi/RetroPie-Setup/.git"
  make_isolated_path_with_stubs dirname git sudo getent id
  run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/retropie/install-retropie.sh"
  assert_success
  assert_file_contains "$TEST_ROOT/calls.log" "PATH retropie-install:update"
  assert_file_contains "$TEST_ROOT/calls.log" "PATH retropie-install:dry-run"
}
