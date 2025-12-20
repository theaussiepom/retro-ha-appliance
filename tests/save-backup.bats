#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'
load 'helpers/common'

setup() {
	setup_test_root
}

teardown() {
	teardown_test_root
}

@test "save-backup no-ops when disabled" {
	export RETRO_HA_SAVE_BACKUP_ENABLED=0
	run bash "$BATS_TEST_DIRNAME/../scripts/nfs/save-backup.sh"
	assert_success
}

@test "save-backup skips during retro mode" {
	export RETRO_HA_SAVE_BACKUP_ENABLED=1
	export SYSTEMCTL_ACTIVE_RETRO=0
	run bash "$BATS_TEST_DIRNAME/../scripts/nfs/save-backup.sh"
	assert_success
}
