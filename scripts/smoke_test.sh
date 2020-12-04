#! /usr/bin/env bash

set -euo pipefail

BASE_URL=${1:-https://ide-integration.batect.dev}

function main() {
  checkPing
  checkConfigSchema

  echoGreenText "Smoke test completed successfully."
}

function checkPing() {
  echoBlueText "Checking /ping..."

  RESPONSE=$(curl \
    --fail \
    --silent \
    --verbose \
    --show-error \
    "$BASE_URL/ping"
  )

  echo
  echo "Response:"
  echo "$RESPONSE"
  echo

  diff -U 9999 <(echo "$RESPONSE") <(echo "pong") || { echo; echoRedText "Response was not as expected. See diff above. '-' represents what was expected, '+' represents what was returned by the API."; exit 1; }

  echo "/ping check passed."
  echo
}

function checkConfigSchema() {
  echoBlueText "Checking /v1/configSchema.json..."

  RESPONSE=$(curl \
    --fail \
    --silent \
    --verbose \
    --show-error \
    "$BASE_URL/v1/configSchema.json"
  )

  echo

  # FIXME: this is a bit of a hack - this checks that the response is well-formed JSON and has a `$schema` key.
  SCHEMA=$(echo "$RESPONSE" | jq -r '.["$schema"]')

  if [[ "$SCHEMA" != "http://json-schema.org/draft-07/schema#" ]]; then
    echo
    echoRedText "Response was not as expected. Response was:"
    echo "$RESPONSE"
    exit 1
  fi

  echo "/v1/configSchema.json check passed."
  echo
}

function echoBlueText() {
  echo "$(tput setaf 4)$1$(tput sgr0)"
}

function echoGreenText() {
  echo "$(tput setaf 2)$1$(tput sgr0)"
}

function echoRedText() {
  echo "$(tput setaf 1)$1$(tput sgr0)"
}

main
