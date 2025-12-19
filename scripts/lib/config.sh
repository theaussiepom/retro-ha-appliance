#!/usr/bin/env bash
set -euo pipefail

# Config loading helpers.

retro_ha_config_env_path() {
	# Location of the config.env file.
	# Tests can override with RETRO_HA_CONFIG_ENV.
	local configured="${RETRO_HA_CONFIG_ENV:-}"
	if [[ -n "$configured" ]]; then
		echo "$configured"
		return 0
	fi
	retro_ha_path "/etc/retro-ha/config.env"
}

load_config_env() {
	local env_path
	env_path="$(retro_ha_config_env_path)"

	if [[ -f "$env_path" ]]; then
		# shellcheck disable=SC1090
		source "$env_path"
	fi
}
