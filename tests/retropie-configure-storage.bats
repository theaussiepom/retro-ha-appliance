#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'
load 'helpers/common'

setup() {
	setup_test_root
	export RETRO_HA_DRY_RUN=1
	export RETRO_HA_ALLOW_NON_ROOT=1

	# Make getent return a home dir under the test root (script uses absolute home paths).
	export GETENT_PASSWD_RETROPI_LINE="retropi:x:1000:1000::${TEST_ROOT}/home/retropi:/bin/bash"

	mkdir -p "$TEST_ROOT/home/retropi/RetroPie"

	# Fake retropie home & retroarch config
	mkdir -p "$TEST_ROOT/opt/retropie/configs/all"
	echo "# test" > "$TEST_ROOT/opt/retropie/configs/all/retroarch.cfg"
}


teardown() {
	teardown_test_root
}

@test "configure-retropie-storage succeeds in dry-run" {
	run bash "$BATS_TEST_DIRNAME/../scripts/retropie/configure-retropie-storage.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "write_kv"
}

@test "configure-retropie-storage skips retroarch config when missing" {
	rm -f "$TEST_ROOT/opt/retropie/configs/all/retroarch.cfg"
	run bash "$BATS_TEST_DIRNAME/../scripts/retropie/configure-retropie-storage.sh"
	assert_success
	assert_output --partial "RetroArch config not found"
}
