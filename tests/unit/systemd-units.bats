#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

KIOSK_RETROPIE_REPO_ROOT="${KIOSK_RETROPIE_REPO_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"

load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-support/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-assert/load"

@test "systemd unit ExecStart references stay under /usr/local/lib/kiosk-retropie" {
	# -h: no filename prefix, -o: only matching part, -E: extended regex (portable for '+').
	run grep -RhoE '^ExecStart=[^ ]+' "$KIOSK_RETROPIE_REPO_ROOT/systemd"
	assert_success

	while IFS= read -r line; do
		# line format: ExecStart=/path
		path="${line#ExecStart=}"
		if [[ "$path" != /usr/local/lib/kiosk-retropie/* ]]; then
			echo "Unexpected ExecStart path: $path" >&2
			return 1
		fi
	done <<<"$output"
}

@test "kiosk and retro-mode units exist" {
	[ -f "$KIOSK_RETROPIE_REPO_ROOT/systemd/kiosk.service" ]
	[ -f "$KIOSK_RETROPIE_REPO_ROOT/systemd/retro-mode.service" ]
}
