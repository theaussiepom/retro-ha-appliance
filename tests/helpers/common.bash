# Common test helpers for bats.

setup_test_root() {
	# Save original PATH so we can restore it during teardown.
	# Some tests intentionally set PATH to $TEST_ROOT/bin; after we delete TEST_ROOT,
	# leaving PATH pointing there can break bats' own cleanup.
	export RETRO_HA_TEST_ORIG_PATH="$PATH"

	TEST_ROOT="$(mktemp -d)"
	export TEST_ROOT

	export RETRO_HA_ROOT="$TEST_ROOT"
	export RETRO_HA_CALLS_FILE="$TEST_ROOT/calls.log"

	# Suite-wide aggregation for path coverage assertions.
	export RETRO_HA_PATH_COVERAGE=1
	# Use a stable file so we can run tests individually (per-test timeout runner).
	export RETRO_HA_PATHS_FILE="${RETRO_HA_PATHS_FILE:-$BATS_TEST_DIRNAME/.tmp/retro-ha-paths.log}"
	# Avoid depending on external dirname (PATH may be intentionally minimal).
	local paths_dir="${RETRO_HA_PATHS_FILE%/*}"
	if [[ -z "$paths_dir" || "$paths_dir" == "$RETRO_HA_PATHS_FILE" ]]; then
		paths_dir="."
	fi
	mkdir -p "$paths_dir"
	export RETRO_HA_CALLS_FILE_APPEND="$RETRO_HA_PATHS_FILE"

	mkdir -p "$TEST_ROOT/etc/retro-ha" "$TEST_ROOT/var/lib/retro-ha" "$TEST_ROOT/var/lock"

	# Ensure stubs override system commands.
	export PATH="$BATS_TEST_DIRNAME/stubs:$PATH"
}

make_isolated_path_with_stubs() {
	# Create a temp bin dir containing only the requested stubs.
	# Usage: make_isolated_path_with_stubs systemctl getent curl
	local bin_dir="$TEST_ROOT/bin"
	mkdir -p "$bin_dir"

	# Provide a small set of core utilities that bats + our tests rely on.
	# This avoids adding /usr/bin to PATH (which would make it hard to test
	# missing-dependency branches for tools like git/sudo).
	# Use symlinks to the real binaries (don't copy system binaries into $TEST_ROOT).
	local core_tools=(env bash sh cat rm mkdir rmdir cut grep sed awk tr sort ls date mktemp head tail)
	local t src
	for t in "${core_tools[@]}"; do
		src=""
		if [[ -x "/bin/$t" ]]; then
			src="/bin/$t"
		elif [[ -x "/usr/bin/$t" ]]; then
			src="/usr/bin/$t"
		fi
		if [[ -n "$src" ]]; then
			ln -sf "$src" "$bin_dir/$t"
		fi
	done

	local stub
	for stub in "$@"; do
		cp "$BATS_TEST_DIRNAME/stubs/$stub" "$bin_dir/$stub"
		chmod +x "$bin_dir/$stub"
	done

	# Expose our curated toolset + /bin (core utilities), but keep /usr/bin hidden
	# so we can still test missing deps like git/sudo.
	export PATH="$bin_dir:/bin"
}

teardown_test_root() {
	# Restore a safe PATH before deleting $TEST_ROOT.
	if [[ -n "${RETRO_HA_TEST_ORIG_PATH:-}" ]]; then
		export PATH="$RETRO_HA_TEST_ORIG_PATH"
	fi

	if [[ -n "${TEST_ROOT:-}" && -d "${TEST_ROOT:-}" ]]; then
		rm -rf "$TEST_ROOT"
	fi
}

write_config_env() {
	local content="$1"
	local path="$TEST_ROOT/etc/retro-ha/config.env"
	printf '%s\n' "$content" >"$path"
	export RETRO_HA_CONFIG_ENV="$path"
}

# Convenience: assert a file contains a substring.
assert_file_contains() {
	local file="$1"
	local needle="$2"
	[[ -f "$file" ]] || return 1
	local grep_bin="grep"
	if [[ -x /usr/bin/grep ]]; then
		grep_bin="/usr/bin/grep"
	elif [[ -x /bin/grep ]]; then
		grep_bin="/bin/grep"
	fi
	"$grep_bin" -Fq -- "$needle" "$file"
}
