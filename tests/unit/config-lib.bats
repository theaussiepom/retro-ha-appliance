#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-support/load"
load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-assert/load"

setup() {
  export KIOSK_RETROPIE_ROOT
  KIOSK_RETROPIE_ROOT="$(mktemp -d)"

  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/common.sh"
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/config.sh"

  unset KIOSK_RETROPIE_CONFIG_ENV || true
}

test_teardown() {
  rm -rf "${KIOSK_RETROPIE_ROOT}" || true
}

@test "kiosk_retropie_config_env_path uses KIOSK_RETROPIE_CONFIG_ENV when set" {
  KIOSK_RETROPIE_CONFIG_ENV="/tmp/special/config.env"
  run kiosk_retropie_config_env_path
  assert_success
  assert_output "/tmp/special/config.env"
}

@test "kiosk_retropie_config_env_path defaults under KIOSK_RETROPIE_ROOT" {
  KIOSK_RETROPIE_ROOT="/tmp/testroot"
  run kiosk_retropie_config_env_path
  assert_success
  assert_output "/tmp/testroot/etc/kiosk-retropie/config.env"
}

@test "load_config_env sources file when present" {
  local env_file
  env_file="${KIOSK_RETROPIE_ROOT}/custom.env"

  printf 'FOO=bar\nBAZ=qux\n' >"$env_file"
  KIOSK_RETROPIE_CONFIG_ENV="$env_file"

  load_config_env

  [ "${FOO}" = "bar" ]
  [ "${BAZ}" = "qux" ]
}

@test "load_config_env is a no-op when file missing" {
  export KIOSK_RETROPIE_CONFIG_ENV="${KIOSK_RETROPIE_ROOT}/missing.env"

  unset FOO || true
  load_config_env

  [ -z "${FOO:-}" ]
}
