#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-support/load"
load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-assert/load"

setup() {
  # Create a minimal fake repo root for scripts to use.
  export KIOSK_RETROPIE_ROOT
  KIOSK_RETROPIE_ROOT="$(mktemp -d)"

  export KIOSK_RETROPIE_LIBDIR=""
  export KIOSK_RETROPIE_ETCDIR=""

  # Source library for kiosk_retropie_path used by healthcheck.
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/common.sh"
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/logging.sh"
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/lib/config.sh"

  # Source the script under test (safe: guarded main).
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/healthcheck.sh"
}

test_teardown() {
  rm -rf "${KIOSK_RETROPIE_ROOT}" || true
}

@test "healthcheck_enter_retro_path prefers KIOSK_RETROPIE_LIBDIR enter-retro-mode.sh" {
  local libdir
  libdir="$(mktemp -d)"
  mkdir -p "$libdir"
  printf '#!/usr/bin/env bash\necho libdir\n' >"$libdir/enter-retro-mode.sh"
  chmod +x "$libdir/enter-retro-mode.sh"

  KIOSK_RETROPIE_LIBDIR="$libdir"

  run healthcheck_enter_retro_path "/does/not/matter"
  assert_success
  assert_output "$libdir/enter-retro-mode.sh"

  rm -rf "$libdir"
}

@test "healthcheck_enter_retro_path falls back to script dir enter-retro-mode.sh" {
  local d
  d="$(mktemp -d)"
  printf '#!/usr/bin/env bash\necho scriptdir\n' >"$d/enter-retro-mode.sh"
  chmod +x "$d/enter-retro-mode.sh"

  KIOSK_RETROPIE_LIBDIR=""

  run healthcheck_enter_retro_path "$d"
  assert_success
  assert_output "$d/enter-retro-mode.sh"

  rm -rf "$d"
}

@test "healthcheck_enter_retro_path falls back to script dir mode/enter-retro-mode.sh" {
  local d
  d="$(mktemp -d)"
  mkdir -p "$d/mode"
  printf '#!/usr/bin/env bash\necho modedir\n' >"$d/mode/enter-retro-mode.sh"
  chmod +x "$d/mode/enter-retro-mode.sh"

  KIOSK_RETROPIE_LIBDIR=""

  run healthcheck_enter_retro_path "$d"
  assert_success
  assert_output "$d/mode/enter-retro-mode.sh"

  rm -rf "$d"
}

@test "healthcheck_enter_retro_path final fallback uses kiosk_retropie_path" {
  KIOSK_RETROPIE_LIBDIR=""

  run healthcheck_enter_retro_path "/definitely/missing"
  assert_success
  assert_output "${KIOSK_RETROPIE_ROOT}/usr/local/lib/kiosk-retropie/enter-retro-mode.sh"
}
