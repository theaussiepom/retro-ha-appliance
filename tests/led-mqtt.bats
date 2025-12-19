#!/usr/bin/env bats

load 'vendor/bats-support/load'
load 'vendor/bats-assert/load'
load 'helpers/common'

setup() {
	setup_test_root
	export RETRO_HA_DRY_RUN=1
}


teardown() {
	teardown_test_root
}

@test "led-mqtt exits 0 when disabled" {
	export RETRO_HA_LED_MQTT_ENABLED=0
	run bash "$BATS_TEST_DIRNAME/../scripts/leds/led-mqtt.sh"
	assert_success
	# Calls may exist due to path coverage markers; ensure we did not subscribe.
	if [[ -f "$TEST_ROOT/calls.log" ]]; then
		! /usr/bin/grep -Fq -- "mosquitto_sub" "$TEST_ROOT/calls.log"
	fi
}

@test "led-mqtt fails if enabled but MQTT_HOST missing" {
	export RETRO_HA_LED_MQTT_ENABLED=1
	unset MQTT_HOST
	run bash "$BATS_TEST_DIRNAME/../scripts/leds/led-mqtt.sh"
	assert_failure
	assert_output --partial "MQTT_HOST is required"
}

@test "led-mqtt records subscribe loop under dry-run" {
	export RETRO_HA_LED_MQTT_ENABLED=1
	export MQTT_HOST="mqtt.local"

	make_isolated_path_with_stubs dirname mosquitto_sub mosquitto_pub

	run bash "$BATS_TEST_DIRNAME/../scripts/leds/led-mqtt.sh"
	assert_success
	assert_file_contains "$TEST_ROOT/calls.log" "mosquitto_sub"
}

@test "led-mqtt publishes state via mosquitto_pub under dry-run" {
	export RETRO_HA_LED_MQTT_ENABLED=1
	export MQTT_HOST="mqtt.local"

	# Force the script to call publish_state path by invoking internal function
	# via sourcing and calling it directly (entrypoint guard should prevent auto-run).
	make_isolated_path_with_stubs dirname mosquitto_pub
	source "$BATS_TEST_DIRNAME/../scripts/leds/led-mqtt.sh"
	publish_state "act" "ON" "retro-ha"

	assert_file_contains "$TEST_ROOT/calls.log" "mosquitto_pub"
	assert_file_contains "$TEST_ROOT/calls.log" "retro-ha/led/act/state"
}
