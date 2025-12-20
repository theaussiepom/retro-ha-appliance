#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'
load 'helpers/common'

setup() {
	setup_test_root
	export RETRO_HA_ALLOW_NON_ROOT=1
	export RETRO_HA_DRY_RUN=1
}

teardown() {
	teardown_test_root
}

@test "install.sh dry-run installs shared libs" {
	run bash "$BATS_TEST_DIRNAME/../scripts/install.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "scripts/lib/common.sh"
	assert_file_contains "$TEST_ROOT/calls.log" "lib/common.sh"
	assert_file_contains "$TEST_ROOT/calls.log" "scripts/lib/logging.sh"
	assert_file_contains "$TEST_ROOT/calls.log" "lib/logging.sh"
}
