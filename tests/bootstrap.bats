#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'
load 'helpers/common'

setup() {
	setup_test_root
}

teardown() {
	teardown_test_root
}

@test "bootstrap exits 0 when installed marker exists" {
	mkdir -p "$TEST_ROOT/var/lib/retro-ha"
	touch "$TEST_ROOT/var/lib/retro-ha/installed"

	run bash "$BATS_TEST_DIRNAME/../scripts/bootstrap.sh"
	assert_success
}

@test "bootstrap fails when network is not ready" {
	write_config_env $'RETRO_HA_REPO_URL=https://example.invalid/repo\nRETRO_HA_REPO_REF=main'
	export GETENT_EXIT_CODE=2
	export CURL_EXIT_CODE=2

	run bash "$BATS_TEST_DIRNAME/../scripts/bootstrap.sh"
	assert_failure
}

@test "bootstrap dry-run records exec of installer" {
	write_config_env $'RETRO_HA_REPO_URL=https://example.invalid/repo\nRETRO_HA_REPO_REF=main'

	# Network OK.
	export GETENT_EXIT_CODE=0
	export CURL_EXIT_CODE=0

	# Provide a fake checkout with an executable install.sh.
	checkout="$TEST_ROOT/opt/retro-ha-appliance"
	mkdir -p "$checkout/scripts"
	cat >"$checkout/scripts/install.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "$checkout/scripts/install.sh"

	export RETRO_HA_CHECKOUT_DIR="$checkout"
	export RETRO_HA_DRY_RUN=1

	run bash "$BATS_TEST_DIRNAME/../scripts/bootstrap.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "exec $checkout/scripts/install.sh"
}
