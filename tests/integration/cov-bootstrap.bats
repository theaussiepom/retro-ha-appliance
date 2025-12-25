#!/usr/bin/env bats

# shellcheck disable=SC1090,SC1091

KIOSK_RETROPIE_REPO_ROOT="${KIOSK_RETROPIE_REPO_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"

load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-support/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/vendor/bats-assert/load"
load "$KIOSK_RETROPIE_REPO_ROOT/tests/helpers/common"

setup() {
	setup_test_root
}

teardown() {
	teardown_test_root
}

@test "bootstrap exits 0 when installed marker exists" {
	mkdir -p "$TEST_ROOT/var/lib/kiosk-retropie"
	touch "$TEST_ROOT/var/lib/kiosk-retropie/installed"

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/bootstrap.sh"
	assert_success
}

@test "bootstrap fails when network is not ready" {
	write_config_env $'KIOSK_RETROPIE_REPO_URL=https://example.invalid/repo\nKIOSK_RETROPIE_REPO_REF=main'
	export GETENT_EXIT_CODE=2
	export CURL_EXIT_CODE=2

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/bootstrap.sh"
	assert_failure
}

@test "bootstrap fails when KIOSK_RETROPIE_REPO_URL missing" {
	write_config_env $'KIOSK_RETROPIE_REPO_REF=main'

	# Network OK.
	export GETENT_EXIT_CODE=0
	export CURL_EXIT_CODE=0

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/bootstrap.sh"
	assert_failure
	assert_output --partial "KIOSK_RETROPIE_REPO_URL is required"
}

@test "bootstrap fails when KIOSK_RETROPIE_REPO_REF missing" {
	write_config_env $'KIOSK_RETROPIE_REPO_URL=https://example.invalid/repo'

	# Network OK.
	export GETENT_EXIT_CODE=0
	export CURL_EXIT_CODE=0

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/bootstrap.sh"
	assert_failure
	assert_output --partial "KIOSK_RETROPIE_REPO_REF is required"
}

@test "bootstrap dry-run records exec of installer" {
	write_config_env $'KIOSK_RETROPIE_REPO_URL=https://example.invalid/repo\nKIOSK_RETROPIE_REPO_REF=main'

	# Network OK.
	export GETENT_EXIT_CODE=0
	export CURL_EXIT_CODE=0

	# Provide a fake checkout with an executable install.sh.
	checkout="$TEST_ROOT/opt/kiosk-retropie"
	mkdir -p "$checkout/scripts"
	cat >"$checkout/scripts/install.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "$checkout/scripts/install.sh"

	export KIOSK_RETROPIE_CHECKOUT_DIR="$checkout"
	export KIOSK_RETROPIE_DRY_RUN=1

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/bootstrap.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "exec $checkout/scripts/install.sh"
}

@test "bootstrap reuses existing checkout when .git exists" {
	write_config_env $'KIOSK_RETROPIE_REPO_URL=https://example.invalid/repo\nKIOSK_RETROPIE_REPO_REF=main'

	# Network OK.
	export GETENT_EXIT_CODE=0
	export CURL_EXIT_CODE=0

	local checkout="$TEST_ROOT/opt/kiosk-retropie"
	mkdir -p "$checkout/.git"
	mkdir -p "$checkout/scripts"
	cat >"$checkout/scripts/install.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "$checkout/scripts/install.sh"

	export KIOSK_RETROPIE_CHECKOUT_DIR="$checkout"
	export KIOSK_RETROPIE_DRY_RUN=1

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/bootstrap.sh"
	assert_success
}

@test "bootstrap fails when installer missing" {
	write_config_env $'KIOSK_RETROPIE_REPO_URL=https://example.invalid/repo\nKIOSK_RETROPIE_REPO_REF=main'

	# Network OK.
	export GETENT_EXIT_CODE=0
	export CURL_EXIT_CODE=0

	local checkout="$TEST_ROOT/opt/kiosk-retropie"
	mkdir -p "$checkout/.git"
	mkdir -p "$checkout/scripts"
	# no install.sh

	export KIOSK_RETROPIE_CHECKOUT_DIR="$checkout"

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/bootstrap.sh"
	assert_failure
	assert_output --partial "Installer not found"
}

@test "bootstrap execs installer when not dry-run" {
	write_config_env $'KIOSK_RETROPIE_REPO_URL=https://example.invalid/repo\nKIOSK_RETROPIE_REPO_REF=main'

	# Network OK.
	export GETENT_EXIT_CODE=0
	export CURL_EXIT_CODE=0

	local checkout="$TEST_ROOT/opt/kiosk-retropie"
	mkdir -p "$checkout/.git"
	mkdir -p "$checkout/scripts"
	cat >"$checkout/scripts/install.sh" <<'EOF'
#!/usr/bin/env bash
echo "installer-ran"
exit 0
EOF
	chmod +x "$checkout/scripts/install.sh"

	export KIOSK_RETROPIE_CHECKOUT_DIR="$checkout"
	export KIOSK_RETROPIE_DRY_RUN=0

	run bash "$KIOSK_RETROPIE_REPO_ROOT/scripts/bootstrap.sh"
	assert_success
	assert_output --partial "installer-ran"
}
