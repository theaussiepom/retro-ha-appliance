#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'
load 'helpers/common'

setup() {
	setup_test_root
	export RETRO_HA_DRY_RUN=1
	export XDG_RUNTIME_DIR="$TEST_ROOT/run/user/1000"
	mkdir -p "$XDG_RUNTIME_DIR"
}


teardown() {
	teardown_test_root
}

@test "ha-kiosk fails if HA_URL missing" {
	unset HA_URL
	run /bin/bash "$BATS_TEST_DIRNAME/../scripts/mode/ha-kiosk.sh"
	assert_failure
}

@test "ha-kiosk chooses chromium-browser when present" {
	export HA_URL="http://example.local"

	# Use isolated path so chromium-browser is the only chromium candidate.
	make_isolated_path_with_stubs dirname chromium-browser xinit getent id

	run /bin/bash "$BATS_TEST_DIRNAME/../scripts/mode/ha-kiosk.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "write_file $XDG_RUNTIME_DIR/retro-ha/ha-xinitrc"
	assert_file_contains "$TEST_ROOT/calls.log" "exec xinit"
}

@test "ha-kiosk fails if no chromium binary" {
	export HA_URL="http://example.local"
	make_isolated_path_with_stubs dirname xinit getent id
	run /bin/bash "$BATS_TEST_DIRNAME/../scripts/mode/ha-kiosk.sh"
	assert_failure
	assert_output --partial "Chromium not found"
}

@test "retro-mode exits 0 when emulationstation missing" {
	# Isolate PATH so emulationstation is not found.
	make_isolated_path_with_stubs dirname xinit
	run /bin/bash "$BATS_TEST_DIRNAME/../scripts/mode/retro-mode.sh"
	assert_success
}

@test "retro-mode fails when xinit missing" {
	make_isolated_path_with_stubs dirname emulationstation
	run /bin/bash "$BATS_TEST_DIRNAME/../scripts/mode/retro-mode.sh"
	assert_failure
	assert_output --partial "xinit not found"
}

@test "retro-mode records xinit exec in dry-run when deps present" {
	make_isolated_path_with_stubs dirname xinit emulationstation
	run /bin/bash "$BATS_TEST_DIRNAME/../scripts/mode/retro-mode.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "write_file $XDG_RUNTIME_DIR/retro-ha/retro-xinitrc"
	assert_file_contains "$TEST_ROOT/calls.log" "exec xinit"
}
