#!/usr/bin/env bash
set -euo pipefail

# Ensure a sane PATH even if the calling shell mutated it.
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# Stable repo-root path for tests (avoids depending on $BATS_TEST_DIRNAME-relative paths).
export RETRO_HA_REPO_ROOT="$ROOT_DIR"

"$ROOT_DIR/tests/bin/fetch-bats.sh" >/dev/null

# Allow `load 'vendor/...'` and `load 'helpers/...'` from nested test folders.
export BATS_LOAD_PATH="$ROOT_DIR/tests:$ROOT_DIR/tests/vendor"
export BATS_LIB_PATH="$ROOT_DIR/tests/vendor:$ROOT_DIR/tests"

shopt -s nullglob

test_files=(
  "$ROOT_DIR/tests/unit"/*.bats
)

# Unit runs intentionally exclude the suite-level path coverage check.
path_coverage_file="$ROOT_DIR/tests/unit/zz-path-coverage.bats"
if [[ -f "$path_coverage_file" ]]; then
  filtered=()
  for f in "${test_files[@]}"; do
    if [[ "$f" != "$path_coverage_file" ]]; then
      filtered+=("$f")
    fi
  done
  test_files=("${filtered[@]}")
fi

shopt -u nullglob
exec "$ROOT_DIR/tests/vendor/bats-core/bin/bats" "${test_files[@]}" "$@"
