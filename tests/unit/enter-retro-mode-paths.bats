#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-support/load"
load "${KIOSK_RETROPIE_REPO_ROOT}/tests/vendor/bats-assert/load"

setup() {
  export KIOSK_RETROPIE_ROOT
  KIOSK_RETROPIE_ROOT="$(mktemp -d)"

  # Source the script under test (guarded main).
  source "${KIOSK_RETROPIE_REPO_ROOT}/scripts/mode/enter-retro-mode.sh"
}

test_teardown() {
  rm -rf "${KIOSK_RETROPIE_ROOT}" || true
}

@test "kiosk_retropie_ledctl_path prefers KIOSK_RETROPIE_LIBDIR when executable exists" {
  local libdir
  libdir="$(mktemp -d)"
  printf '#!/usr/bin/env bash\n' >"$libdir/ledctl.sh"
  chmod +x "$libdir/ledctl.sh"

  export KIOSK_RETROPIE_LIBDIR="$libdir"

  run kiosk_retropie_ledctl_path "/does/not/matter"
  assert_success
  assert_output "$libdir/ledctl.sh"

  rm -rf "$libdir"
}

@test "kiosk_retropie_ledctl_path falls back to <script_dir>/ledctl.sh" {
  local d
  d="$(mktemp -d)"
  printf '#!/usr/bin/env bash\n' >"$d/ledctl.sh"
  chmod +x "$d/ledctl.sh"

  export KIOSK_RETROPIE_LIBDIR=""

  run kiosk_retropie_ledctl_path "$d"
  assert_success
  assert_output "$d/ledctl.sh"

  rm -rf "$d"
}

@test "kiosk_retropie_ledctl_path falls back to <script_dir>/../leds/ledctl.sh" {
  local d
  d="$(mktemp -d)"
  mkdir -p "$d/../leds" 2>/dev/null || true

  # Ensure the sibling leds dir exists under a controlled temp tree.
  local root
  root="$(mktemp -d)"
  mkdir -p "$root/mode" "$root/leds"
  printf '#!/usr/bin/env bash\n' >"$root/leds/ledctl.sh"
  chmod +x "$root/leds/ledctl.sh"

  export KIOSK_RETROPIE_LIBDIR=""

  run kiosk_retropie_ledctl_path "$root/mode"
  assert_success
  assert_output "$root/mode/../leds/ledctl.sh"

  rm -rf "$root"
}

@test "kiosk_retropie_ledctl_path final fallback uses kiosk_retropie_libdir" {
  export KIOSK_RETROPIE_LIBDIR=""

  run kiosk_retropie_ledctl_path "/definitely/missing"
  assert_success
  assert_output "${KIOSK_RETROPIE_ROOT}/usr/local/lib/kiosk-retropie/ledctl.sh"
}
