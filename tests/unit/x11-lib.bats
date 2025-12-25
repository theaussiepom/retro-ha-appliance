#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

# shellcheck source=../vendor/bats-support/load
load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-support/load"
# shellcheck source=../vendor/bats-assert/load
load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-assert/load"

setup() {
  export KIOSK_RETROPIE_ROOT
  KIOSK_RETROPIE_ROOT="$(mktemp -d)"

  # shellcheck source=../../scripts/lib/common.sh
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/common.sh"
  # shellcheck source=../../scripts/lib/x11.sh
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/x11.sh"

  unset XDG_RUNTIME_DIR || true
}

test_teardown() {
  rm -rf "${KIOSK_RETROPIE_ROOT}" || true
}

@test "kiosk_retropie_runtime_dir uses XDG_RUNTIME_DIR when set" {
  export XDG_RUNTIME_DIR="/run/user/999"
  run kiosk_retropie_runtime_dir 123
  assert_success
  assert_output "/run/user/999"
}

@test "kiosk_retropie_runtime_dir falls back to kiosk_retropie_path /run/user/<uid>" {
  KIOSK_RETROPIE_ROOT="/tmp/testroot"
  run kiosk_retropie_runtime_dir 123
  assert_success
  assert_output "/tmp/testroot/run/user/123"
}

@test "kiosk_retropie_state_dir appends /kiosk-retropie" {
  run kiosk_retropie_state_dir "/run/user/1000"
  assert_success
  assert_output "/run/user/1000/kiosk-retropie"
}

@test "kiosk_retropie_xinitrc_path joins state_dir + name" {
  run kiosk_retropie_xinitrc_path "/run/user/1000/kiosk-retropie" "kiosk-xinitrc"
  assert_success
  assert_output "/run/user/1000/kiosk-retropie/kiosk-xinitrc"
}

@test "kiosk_retropie_x_lock_paths yields both lock and socket paths" {
  KIOSK_RETROPIE_ROOT="/tmp/testroot"
  run kiosk_retropie_x_lock_paths ":0"
  assert_success
  assert_output $'/tmp/testroot/tmp/.X0-lock\n/tmp/testroot/tmp/.X11-unix/X0'
}

@test "kiosk_retropie_xinit_exec_record formats xinit command" {
  run kiosk_retropie_xinit_exec_record "/r/kiosk-xinitrc" ":0" "7"
  assert_success
  assert_output "exec xinit /r/kiosk-xinitrc -- /usr/lib/xorg/Xorg :0 vt7 -nolisten tcp -keeptty"
}

@test "kiosk_retropie_xinitrc_prelude contains rotation guard and xset block" {
  run kiosk_retropie_xinitrc_prelude
  assert_success
  assert_output --partial "command -v xset"
  assert_output --partial "KIOSK_RETROPIE_SCREEN_ROTATION"
  assert_output --partial "command -v xrandr"
}
