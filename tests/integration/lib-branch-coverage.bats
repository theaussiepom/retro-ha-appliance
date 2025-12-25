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

@test "lib branch coverage: x11/path/backup helper branches" {
  # Source common first (provides cover_path + kiosk_retropie_realpath_m).
  source "$KIOSK_RETROPIE_REPO_ROOT/scripts/lib/common.sh"

  # X11 helper branches.
  source "$KIOSK_RETROPIE_REPO_ROOT/scripts/lib/x11.sh"

  export XDG_RUNTIME_DIR="$TEST_ROOT/run/user/999"
  run kiosk_retropie_runtime_dir 999
  assert_success

  unset XDG_RUNTIME_DIR
  run kiosk_retropie_runtime_dir 123
  assert_success

  run kiosk_retropie_x_lock_paths ":0"
  assert_success

  run kiosk_retropie_xinit_exec_record "/x" ":0" "7"
  assert_success

  run kiosk_retropie_xinitrc_prelude
  assert_success

  # Path helper branches.
  source "$KIOSK_RETROPIE_REPO_ROOT/scripts/lib/path.sh"

  run kiosk_retropie_path_is_under "/mnt/kiosk-retropie-roms" "/mnt/kiosk-retropie-roms"
  assert_success

  run kiosk_retropie_path_is_under "/mnt/kiosk-retropie-roms" "/mnt/kiosk-retropie-roms/snes"
  assert_success

  run kiosk_retropie_path_is_under "/mnt/kiosk-retropie-roms" "/mnt/kiosk-retropie-roms2"
  assert_failure

  run kiosk_retropie_path_is_under "/" "/etc/kiosk-retropie/config.env"
  assert_success

  # Backup helper branches.
  source "$KIOSK_RETROPIE_REPO_ROOT/scripts/lib/backup.sh"

  run save_backup_rsync_args 0
  assert_success

  run save_backup_rsync_args 1
  assert_success

  # plan-none
  run save_backup_plan "$TEST_ROOT/no-saves" "$TEST_ROOT/no-states" "$TEST_ROOT/bk" "sub"
  assert_success

  mkdir -p "$TEST_ROOT/saves"
  # plan-saves
  run save_backup_plan "$TEST_ROOT/saves" "$TEST_ROOT/no-states" "$TEST_ROOT/bk" "sub"
  assert_success

  mkdir -p "$TEST_ROOT/states"
  # plan-both
  run save_backup_plan "$TEST_ROOT/saves" "$TEST_ROOT/states" "$TEST_ROOT/bk" "sub"
  assert_success

  rm -rf "$TEST_ROOT/saves"
  # plan-states
  run save_backup_plan "$TEST_ROOT/no-saves" "$TEST_ROOT/states" "$TEST_ROOT/bk" "sub"
  assert_success
}
