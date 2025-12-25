#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-support/load"
load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-assert/load"

setup() {
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/common.sh"
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/path.sh"
}

@test "kiosk_retropie_path_is_under true when equal" {
  run kiosk_retropie_path_is_under "/mnt/kiosk-retropie-roms" "/mnt/kiosk-retropie-roms"
  assert_success
}

@test "kiosk_retropie_path_is_under true when child" {
  run kiosk_retropie_path_is_under "/mnt/kiosk-retropie-roms" "/mnt/kiosk-retropie-roms/nes"
  assert_success
}

@test "kiosk_retropie_path_is_under false for prefix trap" {
  run kiosk_retropie_path_is_under "/mnt/kiosk-retropie-roms" "/mnt/kiosk-retropie-roms2"
  assert_failure
}

@test "kiosk_retropie_path_is_under normalizes .. segments" {
  run kiosk_retropie_path_is_under "/mnt/kiosk-retropie-roms" "/mnt/kiosk-retropie-roms/../kiosk-retropie-roms/snes"
  assert_success
}

@test "kiosk_retropie_path_is_under treats base '/' as parent of all" {
  run kiosk_retropie_path_is_under "/" "/etc/kiosk-retropie/config.env"
  assert_success
}
