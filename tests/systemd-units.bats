#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'

@test "systemd unit ExecStart references stay under /usr/local/lib/retro-ha" {
	# -h: no filename prefix, -o: only matching part, -E: extended regex (portable for '+').
	run grep -RhoE '^ExecStart=[^ ]+' "$BATS_TEST_DIRNAME/../systemd"
	assert_success

	while IFS= read -r line; do
		# line format: ExecStart=/path
		path="${line#ExecStart=}"
		if [[ "$path" != /usr/local/lib/retro-ha/* ]]; then
			echo "Unexpected ExecStart path: $path" >&2
			return 1
		fi
	done <<<"$output"
}

@test "ha-kiosk and retro-mode units exist" {
	[ -f "$BATS_TEST_DIRNAME/../systemd/ha-kiosk.service" ]
	[ -f "$BATS_TEST_DIRNAME/../systemd/retro-mode.service" ]
}
