#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

KIOSK_RETROPIE_REPO_ROOT="${KIOSK_RETROPIE_REPO_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"

load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-support/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-assert/load"

@test "path coverage (integration): all non-lib required IDs were hit" {
  required_file="$KIOSK_RETROPIE_REPO_ROOT/tests/coverage/required-paths.txt"
  paths_log="${KIOSK_RETROPIE_PATHS_FILE:-$KIOSK_RETROPIE_REPO_ROOT/tests/.tmp/kiosk-retropie-paths.log}"

  [ -f "$required_file" ]
  [ -f "$paths_log" ]

  missing=()
  while IFS= read -r line; do
    case "$line" in
      ''|'#'*) continue ;;
    esac

    # Integration scope: enforce everything except lib-*.
    case "$line" in
      lib-*) continue ;;
      *) ;;
    esac

    if ! /usr/bin/grep -Fq -- "PATH $line" "$paths_log"; then
      missing+=("$line")
    fi
  done < "$required_file"

  if [[ "${#missing[@]}" -gt 0 ]]; then
    echo "Missing path coverage ids (${#missing[@]}):" >&2
    printf '%s\n' "${missing[@]}" >&2
    return 1
  fi
}
