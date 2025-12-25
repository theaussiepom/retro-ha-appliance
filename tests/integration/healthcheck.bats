#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

KIOSK_RETROPIE_REPO_ROOT="${KIOSK_RETROPIE_REPO_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"

load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-support/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-assert/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/helpers/common"

setup() {
	setup_test_root
	# Ensure no mode is active.
	export SYSTEMCTL_ACTIVE_KIOSK=1
	export SYSTEMCTL_ACTIVE_RETRO=1
}

teardown() {
	teardown_test_root
}

@test "healthcheck exits 0 when kiosk active" {
	export SYSTEMCTL_ACTIVE_KIOSK=0
	export SYSTEMCTL_ACTIVE_RETRO=1

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/healthcheck.sh"
	assert_success
}

@test "healthcheck exits 0 when Retro mode active" {
	export SYSTEMCTL_ACTIVE_KIOSK=1
	export SYSTEMCTL_ACTIVE_RETRO=0

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/healthcheck.sh"
	assert_success
}

@test "healthcheck triggers failover when no mode active (dry-run)" {
	export SYSTEMCTL_ACTIVE_KIOSK=1
	export SYSTEMCTL_ACTIVE_RETRO=1
	export KIOSK_RETROPIE_DRY_RUN=1

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/healthcheck.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "enter-retro-mode.sh"
}

@test "healthcheck chooses enter-retro-mode from KIOSK_RETROPIE_LIBDIR when present" {
	export SYSTEMCTL_ACTIVE_KIOSK=1
	export SYSTEMCTL_ACTIVE_RETRO=1
	export KIOSK_RETROPIE_DRY_RUN=1

	local libdir="$TEST_ROOT/lib"
	mkdir -p "$libdir"
	echo '#!/usr/bin/env bash' >"$libdir/enter-retro-mode.sh"
	echo 'exit 0' >>"$libdir/enter-retro-mode.sh"
	chmod +x "$libdir/enter-retro-mode.sh"
	export KIOSK_RETROPIE_LIBDIR="$libdir"

	source "$KIOSK_RETROPIE_REPO_ROOT/scripts/healthcheck.sh"
	SCRIPT_DIR="$TEST_ROOT/scripts"
	mkdir -p "$SCRIPT_DIR"

	run main
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "$libdir/enter-retro-mode.sh"
}

@test "healthcheck chooses enter-retro-mode from SCRIPT_DIR when present" {
	export SYSTEMCTL_ACTIVE_KIOSK=1
	export SYSTEMCTL_ACTIVE_RETRO=1
	export KIOSK_RETROPIE_DRY_RUN=1
	unset KIOSK_RETROPIE_LIBDIR

	source "$KIOSK_RETROPIE_REPO_ROOT/scripts/healthcheck.sh"
	SCRIPT_DIR="$TEST_ROOT/scripts"
	mkdir -p "$SCRIPT_DIR"
	echo '#!/usr/bin/env bash' >"$SCRIPT_DIR/enter-retro-mode.sh"
	echo 'exit 0' >>"$SCRIPT_DIR/enter-retro-mode.sh"
	chmod +x "$SCRIPT_DIR/enter-retro-mode.sh"

	run main
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "$SCRIPT_DIR/enter-retro-mode.sh"
}

@test "healthcheck chooses enter-retro-mode from SCRIPT_DIR/mode when present" {
	export SYSTEMCTL_ACTIVE_KIOSK=1
	export SYSTEMCTL_ACTIVE_RETRO=1
	export KIOSK_RETROPIE_DRY_RUN=1
	unset KIOSK_RETROPIE_LIBDIR

	source "$KIOSK_RETROPIE_REPO_ROOT/scripts/healthcheck.sh"
	SCRIPT_DIR="$TEST_ROOT/scripts"
	mkdir -p "$SCRIPT_DIR/mode"
	echo '#!/usr/bin/env bash' >"$SCRIPT_DIR/mode/enter-retro-mode.sh"
	echo 'exit 0' >>"$SCRIPT_DIR/mode/enter-retro-mode.sh"
	chmod +x "$SCRIPT_DIR/mode/enter-retro-mode.sh"

	run main
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "$SCRIPT_DIR/mode/enter-retro-mode.sh"
}

@test "healthcheck falls back to /usr/local/lib/kiosk-retropie enter-retro-mode" {
	export SYSTEMCTL_ACTIVE_KIOSK=1
	export SYSTEMCTL_ACTIVE_RETRO=1
	export KIOSK_RETROPIE_DRY_RUN=1
	unset KIOSK_RETROPIE_LIBDIR

	source "$KIOSK_RETROPIE_REPO_ROOT/scripts/healthcheck.sh"
	SCRIPT_DIR="$TEST_ROOT/scripts"
	mkdir -p "$SCRIPT_DIR"

	run main
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "enter-retro-mode.sh"
}
