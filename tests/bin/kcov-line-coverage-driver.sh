#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

export RETRO_HA_ROOT="$work_dir/root"
export RETRO_HA_CALLS_FILE="$work_dir/calls.log"

mkdir -p \
  "$RETRO_HA_ROOT/etc/retro-ha" \
  "$RETRO_HA_ROOT/var/lib/retro-ha" \
  "$RETRO_HA_ROOT/var/lock"

# Create a small set of stubs used to force specific branches.
stub_bin="$work_dir/bin"
mkdir -p "$stub_bin"

cat >"$stub_bin/apt-cache" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Minimal apt-cache stub for install.sh coverage.
# Control behavior with KCOV_APT_CACHE_MODE:
#   browser  -> apt-cache show chromium-browser succeeds
#   chromium -> apt-cache show chromium succeeds
#   none     -> both fail
mode="${KCOV_APT_CACHE_MODE:-none}"

if [[ "${1:-}" == "show" ]]; then
  pkg="${2:-}"
  case "$mode:$pkg" in
    browser:chromium-browser) exit 0 ;;
    chromium:chromium) exit 0 ;;
  esac
  exit 1
fi

exit 0
EOF
chmod +x "$stub_bin/apt-cache"

cat >"$stub_bin/id" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# id stub that can simulate retropi existing or not.
if [[ "${1:-}" == "-u" && "${2:-}" == "retropi" ]]; then
  if [[ "${KCOV_RETROPI_EXISTS:-1}" == "1" ]]; then
    echo 1000
    exit 0
  fi
  exit 1
fi

exec /usr/bin/id "$@"
EOF
chmod +x "$stub_bin/id"

cat >"$stub_bin/flock" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# flock stub used to hit installer lock branches.
# KCOV_FLOCK_MODE:
#   ok            -> succeed
#   fail          -> fail (simulate lock contention)
#   create_marker -> create marker file then succeed (simulate marker appearing)
mode="${KCOV_FLOCK_MODE:-ok}"

if [[ "$mode" == "fail" ]]; then
  exit 1
fi

if [[ "$mode" == "create_marker" ]]; then
  marker="${RETRO_HA_INSTALLED_MARKER:-}"
  if [[ -n "$marker" ]]; then
    mkdir -p "$(dirname "$marker")"
    : >"$marker"
  fi
fi

exit 0
EOF
chmod +x "$stub_bin/flock"

# Prefer our stubs, then the repo's test stubs, then system bins.
export PATH="$stub_bin:$ROOT_DIR/tests/stubs:/usr/bin:/bin"

# Source lib helpers and exercise edge cases.
# shellcheck source=scripts/lib/logging.sh
source "$ROOT_DIR/scripts/lib/logging.sh"
# shellcheck source=scripts/lib/common.sh
source "$ROOT_DIR/scripts/lib/common.sh"
# shellcheck source=scripts/lib/config.sh
source "$ROOT_DIR/scripts/lib/config.sh"

(
  unset RETRO_HA_ROOT
  retro_ha_root >/dev/null
)
(
  export RETRO_HA_ROOT=""
  retro_ha_root >/dev/null
)
(
  export RETRO_HA_ROOT="/"
  retro_ha_root >/dev/null
)
(
  export RETRO_HA_ROOT="/tmp/retro-ha-root/"
  retro_ha_root >/dev/null
)

retro_ha_path /etc/retro-ha/config.env >/dev/null
retro_ha_path relative/path >/dev/null

retro_ha_dirname "" >/dev/null
retro_ha_dirname "foo" >/dev/null
retro_ha_dirname "/foo" >/dev/null
retro_ha_dirname "/foo/" >/dev/null
retro_ha_dirname "/" >/dev/null

# record_call / cover_path / run_cmd branches.
export RETRO_HA_CALLS_FILE="$work_dir/calls.log"
export RETRO_HA_CALLS_FILE_APPEND="$work_dir/calls-append.log"
record_call "hello" >/dev/null

export RETRO_HA_PATH_COVERAGE=0
cover_path "no-op" >/dev/null
export RETRO_HA_PATH_COVERAGE=1
cover_path "do-op" >/dev/null

export RETRO_HA_DRY_RUN=1
run_cmd echo "dry" >/dev/null
export RETRO_HA_DRY_RUN=0
run_cmd true >/dev/null

retro_ha_realpath_m "/a/b/../c" >/dev/null
retro_ha_realpath_m "a/./b" >/dev/null

export RETRO_HA_DRY_RUN=1
svc_start foo.service >/dev/null
svc_stop foo.service >/dev/null

# require_cmd: success + failure branch (failure in subshell so we keep going).
require_cmd bash >/dev/null
(
  set +e
  require_cmd this-command-does-not-exist 2>/dev/null
) || true

# Prepare a config.env for bootstrap/install to load.
cat >"$RETRO_HA_ROOT/etc/retro-ha/config.env" <<EOF
RETRO_HA_REPO_URL=https://example.invalid/repo.git
RETRO_HA_REPO_REF=main
EOF

# Exercise bootstrap branches.
export RETRO_HA_DRY_RUN=1
export GETENT_HOSTS_EXIT_CODE=0
export CURL_EXIT_CODE=0

checkout_dir="$RETRO_HA_ROOT/opt/retro-ha-appliance"
mkdir -p "$checkout_dir"

# Clone path (no .git dir)
rm -rf "$checkout_dir/.git"
(
  set +e
  RETRO_HA_CHECKOUT_DIR="$checkout_dir" \
    RETRO_HA_REPO_URL=https://example.invalid/repo.git \
    RETRO_HA_REPO_REF=main \
    bash "$ROOT_DIR/scripts/bootstrap.sh" >/dev/null
) || true

# Already cloned path
mkdir -p "$checkout_dir/.git"
(
  set +e
  RETRO_HA_CHECKOUT_DIR="$checkout_dir" \
    RETRO_HA_REPO_URL=https://example.invalid/repo.git \
    RETRO_HA_REPO_REF=main \
    bash "$ROOT_DIR/scripts/bootstrap.sh" >/dev/null
) || true

# Missing installer branch
(
  set +e
  RETRO_HA_CHECKOUT_DIR="$RETRO_HA_ROOT/opt/missing-installer" \
    RETRO_HA_REPO_URL=https://example.invalid/repo.git \
    RETRO_HA_REPO_REF=main \
    bash "$ROOT_DIR/scripts/bootstrap.sh" >/dev/null
) || true

# Exercise install.sh branches.
export RETRO_HA_ALLOW_NON_ROOT=1
export RETRO_HA_DRY_RUN=1
export RETRO_HA_INSTALLED_MARKER="$RETRO_HA_ROOT/var/lib/retro-ha/installed"

# Marker present early-exit.
: >"$RETRO_HA_INSTALLED_MARKER"
(
  set +e
  KCOV_RETROPI_EXISTS=1 KCOV_APT_CACHE_MODE=none KCOV_FLOCK_MODE=ok \
    "$ROOT_DIR/scripts/install.sh" >/dev/null
) || true
rm -f "$RETRO_HA_INSTALLED_MARKER"

# Lock contention.
(
  set +e
  KCOV_RETROPI_EXISTS=1 KCOV_APT_CACHE_MODE=none KCOV_FLOCK_MODE=fail \
    "$ROOT_DIR/scripts/install.sh" >/dev/null
) || true

# Marker appears while waiting for lock.
(
  set +e
  KCOV_RETROPI_EXISTS=1 KCOV_APT_CACHE_MODE=none KCOV_FLOCK_MODE=create_marker \
    "$ROOT_DIR/scripts/install.sh" >/dev/null
) || true
rm -f "$RETRO_HA_INSTALLED_MARKER"

# Full-ish dry-run with different apt-cache outcomes and user present/missing.
(
  KCOV_RETROPI_EXISTS=1 KCOV_APT_CACHE_MODE=browser KCOV_FLOCK_MODE=ok \
    "$ROOT_DIR/scripts/install.sh" >/dev/null
)
(
  KCOV_RETROPI_EXISTS=0 KCOV_APT_CACHE_MODE=chromium KCOV_FLOCK_MODE=ok \
    "$ROOT_DIR/scripts/install.sh" >/dev/null
)
(
  KCOV_RETROPI_EXISTS=0 KCOV_APT_CACHE_MODE=none KCOV_FLOCK_MODE=ok \
    RETRO_HA_INSTALL_RETROPIE=1 \
    "$ROOT_DIR/scripts/install.sh" >/dev/null
)

# Require-root failure branch.
(
  set +e
  RETRO_HA_ALLOW_NON_ROOT=0 KCOV_RETROPI_EXISTS=1 KCOV_APT_CACHE_MODE=none KCOV_FLOCK_MODE=ok \
    "$ROOT_DIR/scripts/install.sh" >/dev/null
) || true
