#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

KIOSK_RETROPIE_REPO_ROOT="${KIOSK_RETROPIE_REPO_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"

load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-support/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-assert/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/helpers/common"

setup() {
	setup_test_root
	export KIOSK_RETROPIE_DRY_RUN=1

	# Provide a fake ledctl in repo layout so enter-retro-mode finds it.
	mkdir -p "$TEST_ROOT/tmp"
}

teardown() {
	teardown_test_root
}

@test "enter-kiosk-mode stops retro and starts kiosk" {
	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/mode/enter-kiosk-mode.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl stop retro-mode.service"
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl start kiosk.service"
}

@test "enter-retro-mode stops kiosk and starts retro" {
	# Ensure enter-retro-mode can find ledctl via repo layout.
	# It will be recorded (dry-run) rather than executed.
	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/mode/enter-retro-mode.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl stop kiosk.service"
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl start retro-mode.service"
	assert_file_contains "$TEST_ROOT/calls.log" "ledctl.sh all on"
}

@test "enter-retro-mode supports KIOSK_RETROPIE_SKIP_LEDCTL=1" {
	export KIOSK_RETROPIE_SKIP_LEDCTL=1

	# Source + call main in-process so kcov line coverage can see this branch.
	source "$KIOSK_RETROPIE_REPO_ROOT/scripts/mode/enter-retro-mode.sh"
	main
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl stop kiosk.service"
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl start retro-mode.service"

	# Should not attempt to force LEDs via ledctl.
	if [[ -f "$TEST_ROOT/calls.log" ]]; then
		! /usr/bin/grep -Fq -- "ledctl.sh all on" "$TEST_ROOT/calls.log"
	fi
}

@test "enter-retro-mode ledctl path selection covers all branches" {
	source "$KIOSK_RETROPIE_REPO_ROOT/scripts/mode/enter-retro-mode.sh"

	# Case 1: KIOSK_RETROPIE_LIBDIR/ledctl.sh is executable.
	local libdir="$TEST_ROOT/lib"
	mkdir -p "$libdir"
	echo '#!/usr/bin/env bash' >"$libdir/ledctl.sh"
	echo 'exit 0' >>"$libdir/ledctl.sh"
	chmod +x "$libdir/ledctl.sh"
	export KIOSK_RETROPIE_LIBDIR="$libdir"
	run kiosk_retropie_ledctl_path
	assert_success
	assert_output "$libdir/ledctl.sh"

	# Case 2: SCRIPT_DIR/ledctl.sh exists.
	unset KIOSK_RETROPIE_LIBDIR
	SCRIPT_DIR="$TEST_ROOT/mode"
	mkdir -p "$SCRIPT_DIR"
	echo '#!/usr/bin/env bash' >"$SCRIPT_DIR/ledctl.sh"
	echo 'exit 0' >>"$SCRIPT_DIR/ledctl.sh"
	chmod +x "$SCRIPT_DIR/ledctl.sh"
	run kiosk_retropie_ledctl_path
	assert_success
	assert_output "$SCRIPT_DIR/ledctl.sh"

	# Case 3: SCRIPT_DIR/../leds/ledctl.sh exists.
	rm -f "$SCRIPT_DIR/ledctl.sh"
	mkdir -p "$TEST_ROOT/leds"
	echo '#!/usr/bin/env bash' >"$TEST_ROOT/leds/ledctl.sh"
	echo 'exit 0' >>"$TEST_ROOT/leds/ledctl.sh"
	chmod +x "$TEST_ROOT/leds/ledctl.sh"
	run kiosk_retropie_ledctl_path
	assert_success
	assert_output --partial "/leds/ledctl.sh"

	# Case 4: fallback path when nothing exists (not executable).
	rm -f "$TEST_ROOT/leds/ledctl.sh"
	run kiosk_retropie_ledctl_path
	assert_success
	assert_output --partial "/usr/local/lib/kiosk-retropie/ledctl.sh"
}

@test "enter-retro-mode skips led forcing when ledctl missing" {
	# Run in a subshell with SCRIPT_DIR set so that none of the candidate ledctl
	# paths exist.
	export KIOSK_RETROPIE_DRY_RUN=1
	unset KIOSK_RETROPIE_LIBDIR

	local isolated_dir="$TEST_ROOT/isolated/mode"
	mkdir -p "$isolated_dir"

	run bash -c '
		set -euo pipefail
		source "$1"
		SCRIPT_DIR="$2"
		main
	' bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/mode/enter-retro-mode.sh" "$isolated_dir"
	assert_success
	# Should still switch modes.
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl stop kiosk.service"
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl start retro-mode.service"
	# But should not attempt to run ledctl.
	if [[ -f "$TEST_ROOT/calls.log" ]]; then
		! /usr/bin/grep -Fq -- "ledctl.sh all on" "$TEST_ROOT/calls.log"
	fi
}
