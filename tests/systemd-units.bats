#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'

@test "systemd unit ExecStart references stay under /usr/local/lib/retro-ha" {
	run grep -R "^ExecStart=" "$BATS_TEST_DIRNAME/../systemd"
	assert_success
	assert_output --partial "/usr/local/lib/retro-ha"
}

@test "ha-kiosk and retro-mode units exist" {
	[ -f "$BATS_TEST_DIRNAME/../systemd/ha-kiosk.service" ]
	[ -f "$BATS_TEST_DIRNAME/../systemd/retro-mode.service" ]
}
