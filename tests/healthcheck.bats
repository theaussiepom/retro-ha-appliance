#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'
load 'helpers/common'

setup() {
	setup_test_root
	# Ensure no mode is active.
	export SYSTEMCTL_ACTIVE_HA=1
	export SYSTEMCTL_ACTIVE_RETRO=1
}

teardown() {
	teardown_test_root
}

@test "healthcheck triggers failover when no mode active (dry-run)" {
	export SYSTEMCTL_ACTIVE_HA=1
	export SYSTEMCTL_ACTIVE_RETRO=1
	export RETRO_HA_DRY_RUN=1

	run bash "$BATS_TEST_DIRNAME/../scripts/healthcheck.sh"
	assert_success

	assert_file_contains "$TEST_ROOT/calls.log" "enter-retro-mode.sh"
}

@test "healthcheck exits 0 when HA kiosk active" {
	export SYSTEMCTL_ACTIVE_HA=0
	export SYSTEMCTL_ACTIVE_RETRO=1

	run bash "$BATS_TEST_DIRNAME/../scripts/healthcheck.sh"
	assert_success
}
