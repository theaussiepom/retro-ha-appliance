#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'
load 'helpers/common'

setup() {
	setup_test_root
	export RETRO_HA_DRY_RUN=1

	# Provide a fake ledctl in repo layout so enter-retro-mode finds it.
	mkdir -p "$TEST_ROOT/tmp"
}

teardown() {
	teardown_test_root
}

@test "enter-ha-mode stops retro and starts ha" {
	run bash "$BATS_TEST_DIRNAME/../scripts/mode/enter-ha-mode.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl stop retro-mode.service"
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl start ha-kiosk.service"
}

@test "enter-retro-mode stops ha and starts retro" {
	# Ensure enter-retro-mode can find ledctl via repo layout.
	# It will be recorded (dry-run) rather than executed.
	run bash "$BATS_TEST_DIRNAME/../scripts/mode/enter-retro-mode.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl stop ha-kiosk.service"
	assert_file_contains "$TEST_ROOT/calls.log" "systemctl start retro-mode.service"
	assert_file_contains "$TEST_ROOT/calls.log" "ledctl.sh all on"
}
