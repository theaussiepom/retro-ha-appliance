#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT_DIR/tests/bin/fetch-bats.sh" >/dev/null

export BATS_LIB_PATH="$ROOT_DIR/tests/vendor"

if ! command -v kcov >/dev/null 2>&1; then
  echo "kcov not found on PATH" >&2
  exit 127
fi

out_dir="${KCOV_OUT_DIR:-$ROOT_DIR/coverage}"
rm -rf "$out_dir"
mkdir -p "$out_dir"

# Run the Bats suite under kcov to gather coverage for scripts/**.
# --bash-parse improves bash coverage accuracy.
# Exclude tests and vendored bats libs.
exec kcov \
  --bash-parse \
  --include-path="$ROOT_DIR/scripts" \
  --exclude-pattern="$ROOT_DIR/tests,$ROOT_DIR/tests/vendor" \
  "$out_dir" \
  "$ROOT_DIR/tests/bin/run-bats.sh" "$@"
