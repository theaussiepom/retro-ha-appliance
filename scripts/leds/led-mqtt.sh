#!/usr/bin/env bash
set -euo pipefail

# A tiny MQTT subscriber that lets Home Assistant toggle the Pi LEDs.
#
# Requires:
#   - mosquitto_sub + mosquitto_pub (package: mosquitto-clients)
#   - scripts/leds/ledctl.sh installed at /usr/local/lib/retro-ha/ledctl.sh
#
# Topics (default prefix: retro-ha):
#   <prefix>/led/act/set   payload: ON|OFF
#   <prefix>/led/pwr/set   payload: ON|OFF
#   <prefix>/led/all/set   payload: ON|OFF
#
# State topics:
#   <prefix>/led/act/state payload: ON|OFF
#   <prefix>/led/pwr/state payload: ON|OFF

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

LIB_DIR=""
if [[ -d "$SCRIPT_DIR/lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/lib"
elif [[ -d "$SCRIPT_DIR/../lib" ]]; then
  LIB_DIR="$SCRIPT_DIR/../lib"
else
  echo "retro-ha-led-mqtt [error]: unable to locate scripts/lib" >&2
  exit 1
fi

# shellcheck source=scripts/lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=scripts/lib/common.sh
source "$LIB_DIR/common.sh"

LEDCTL_PATH="${RETRO_HA_LEDCTL_PATH:-$(retro_ha_path /usr/local/lib/retro-ha/ledctl.sh)}"

mosq_args() {
  local args=()

  args+=("-h" "${MQTT_HOST}")
  args+=("-p" "${MQTT_PORT:-1883}")

  if [[ -n "${MQTT_USERNAME:-}" ]]; then
    args+=("-u" "${MQTT_USERNAME}")
  fi
  if [[ -n "${MQTT_PASSWORD:-}" ]]; then
    args+=("-P" "${MQTT_PASSWORD}")
  fi

  # Optional TLS (keep minimal; assume system CA store).
  if [[ "${MQTT_TLS:-0}" == "1" ]]; then
    args+=("--tls-version" "tlsv1.2")
  fi

  printf '%s\n' "${args[@]}"
}

publish_state() {
  local target="$1"  # act|pwr
  local payload="$2" # ON|OFF
  local prefix="$3"

  cover_path "led-mqtt:publish-state"

  local state_topic
  state_topic="${prefix}/led/${target}/state"

  local args=()
  local line
  while IFS= read -r line; do
    args+=("$line")
  done < <(mosq_args)
  run_cmd mosquitto_pub "${args[@]}" -t "$state_topic" -m "$payload" -r
}

handle_set() {
  local target="$1" # act|pwr|all
  local payload_raw="$2"
  local prefix="$3"

  local payload
  payload="$(tr '[:lower:]' '[:upper:]' <<< "$payload_raw")"

  local state
  case "$payload" in
    ON) state="on" ;;
    OFF) state="off" ;;
    *)
      log "Ignoring payload '$payload_raw' for target '$target'"
      return 0
      ;;
  esac

  if [[ ! -x "$LEDCTL_PATH" ]]; then
    die "LED control script missing or not executable: $LEDCTL_PATH"
  fi

  run_cmd "$LEDCTL_PATH" "$target" "$state"

  # Publish retained state for HA UI.
  case "$target" in
    act | pwr)
      publish_state "$target" "$payload" "$prefix"
      ;;
    all)
      publish_state "act" "$payload" "$prefix" || true
      publish_state "pwr" "$payload" "$prefix" || true
      ;;
  esac
}

main() {
  export RETRO_HA_LOG_PREFIX="retro-ha-led-mqtt"

  if [[ "${RETRO_HA_LED_MQTT_ENABLED:-0}" != "1" ]]; then
    cover_path "led-mqtt:disabled"
    log "RETRO_HA_LED_MQTT_ENABLED!=1; exiting (disabled)."
    exit 0
  fi

  if [[ -z "${MQTT_HOST:-}" ]]; then
    cover_path "led-mqtt:missing-mqtt-host"
    die "MQTT_HOST is required"
  fi

  local prefix="${RETRO_HA_MQTT_TOPIC_PREFIX:-retro-ha}"
  local topic_filter="${prefix}/led/+/set"

  local args=()
  local line
  while IFS= read -r line; do
    args+=("$line")
  done < <(mosq_args)

  log "Subscribing to ${topic_filter}"

  cover_path "led-mqtt:subscribing"

  # -v prints "<topic> <payload>" per line.
  mosquitto_sub "${args[@]}" -v -t "$topic_filter" | while read -r topic payload; do
    # topic: <prefix>/led/<target>/set
    local target
    target="${topic#"${prefix}/led/"}"
    target="${target%/set}"

    case "$target" in
      act | pwr | all)
        handle_set "$target" "$payload" "$prefix" || true
        ;;
      *)
        log "Ignoring unknown target '$target' (topic: $topic)"
        ;;
    esac
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
