#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

out_dir="${KCOV_OUT_DIR:-$ROOT_DIR/coverage}"

python3 - <<'PY' "$out_dir"
import glob
import json
import os
import sys

out_dir = sys.argv[1]

candidates = glob.glob(os.path.join(out_dir, "**", "coverage.json"), recursive=True)
if not candidates:
    print(f"No kcov coverage.json found under: {out_dir}", file=sys.stderr)
    sys.exit(2)

# Prefer merged coverage if present.
preferred = None
for p in candidates:
    if p.endswith(os.path.join("kcov-merged", "coverage.json")):
        preferred = p
        break
coverage_path = preferred or sorted(candidates)[0]

with open(coverage_path, "r", encoding="utf-8") as f:
    data = json.load(f)

# kcov formats vary; try to find totals.
covered = total = None

if isinstance(data, dict):
    totals = data.get("totals")
    if isinstance(totals, dict):
        covered = totals.get("covered_lines") or totals.get("covered")
        total = totals.get("lines") or totals.get("total_lines") or totals.get("total")

    if covered is None or total is None:
        # Some versions put totals at top-level.
        covered = covered or data.get("covered_lines") or data.get("covered")
        total = total or data.get("lines") or data.get("total_lines") or data.get("total")

if covered is None or total is None:
    print(f"Unrecognized kcov JSON schema in {coverage_path}", file=sys.stderr)
    sys.exit(3)

covered = int(covered)
total = int(total)

pct = 100.0 if total == 0 else (covered / total) * 100.0
print(f"kcov: covered_lines={covered} total_lines={total} percent={pct:.4f} (from {coverage_path})")

# Allow tiny float noise.
if pct < 99.9999:
    sys.exit(1)
PY
