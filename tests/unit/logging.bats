#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

KIOSK_RETROPIE_REPO_ROOT="${KIOSK_RETROPIE_REPO_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"

load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-support/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-assert/load"

@test "logging warn path is covered" {
	run bash -c '
		set -euo pipefail
		source "$1"
		export KIOSK_RETROPIE_LOG_PREFIX="test"
		warn "hello"
	' bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/lib/logging.sh"
	assert_success
	assert_output --partial "[warn]"
}

@test "logging die path is covered" {
	# die() should exit non-zero; run in a subshell so the test can assert.
	run bash -c 'source "$1"; die "nope"' bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/lib/logging.sh"
	assert_failure
	assert_output --partial "[error]"
}
