#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

KIOSK_RETROPIE_REPO_ROOT="${KIOSK_RETROPIE_REPO_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"

load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-support/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-assert/load"

@test "required paths list covers all script path IDs" {
  run bash -c '
    set -euo pipefail
    repo_root="$1"

    "$repo_root/tests/bin/list-path-ids.sh" > /tmp/kiosk-retropie-script-ids.txt
    grep -vE "^(#|[[:space:]]*$)" "$repo_root/tests/coverage/required-paths.txt" | sort -u > /tmp/kiosk-retropie-required-ids.txt

    # Show up to 50 missing IDs for debugging.
    missing=$(comm -23 /tmp/kiosk-retropie-script-ids.txt /tmp/kiosk-retropie-required-ids.txt | head -n 50)
    if [[ -n "$missing" ]]; then
      echo "Missing required-paths entries:" >&2
      echo "$missing" >&2
      exit 1
    fi

    # Also fail if required-paths contains stale entries not present in scripts.
    extra=$(comm -13 /tmp/kiosk-retropie-script-ids.txt /tmp/kiosk-retropie-required-ids.txt | head -n 50)
    if [[ -n "$extra" ]]; then
      echo "Stale required-paths entries (not present in scripts):" >&2
      echo "$extra" >&2
      exit 1
    fi
  ' bash "$KIOSK_RETROPIE_REPO_ROOT"
  assert_success
}
