#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'

@test "path coverage: all required path IDs were hit" {
  required_file="$BATS_TEST_DIRNAME/coverage/required-paths.txt"
  paths_log="${RETRO_HA_PATHS_FILE:-$BATS_TEST_DIRNAME/.tmp/retro-ha-paths.log}"

  [ -f "$required_file" ]
  [ -f "$paths_log" ]

  while IFS= read -r line; do
    case "$line" in
      ''|'#'*) continue ;;
    esac

    # Match exact token "PATH <id>" in the log.
      if ! /usr/bin/grep -Fq -- "PATH $line" "$paths_log"; then
      echo "Missing path coverage id: $line" >&2
      return 1
    fi
  done < "$required_file"
}
