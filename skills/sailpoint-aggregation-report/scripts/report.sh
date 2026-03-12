#!/usr/bin/env bash
set -euo pipefail

PERIOD="${1:-1w}"

# sail api sends JSON to stderr, mixed with log lines. This helper extracts just the JSON.
sail_api() {
  local method="$1"
  local path="$2"
  shift 2

  if [[ "$method" == "post" || "$method" == "put" || "$method" == "patch" ]]; then
    local has_body=false
    for arg in "$@"; do
      if [[ "$arg" == "--body" || "$arg" == "-b" || "$arg" == "--body-file" || "$arg" == "-f" ]]; then
        has_body=true
        break
      fi
    done
    if ! $has_body; then
      sail api "$method" "$path" --body '{}' "$@" 2>&1 | grep -v '^[0-9]\{4\}/' | grep -v '^Status:' | grep -v '^Error:'
      return
    fi
  fi

  sail api "$method" "$path" "$@" 2>&1 | grep -v '^[0-9]\{4\}/' | grep -v '^Status:' | grep -v '^Error:'
}

echo "============================================"
echo " Aggregation Report (last $PERIOD)"
echo "============================================"
echo ""

EVENTS=$(sail_api post /v2025/search --body "{\"indices\": [\"events\"], \"query\": { \"query\": \"type:source_management AND created:[now-${PERIOD} TO now]\" }}")

# Summary by action
echo "--- Event Summary ---"
echo "$EVENTS" | jq '
  group_by(.action) |
  map({action: .[0].action, count: length}) |
  sort_by(-.count) | .[] |
  "\(.count)\t\(.action)"' -r
echo ""

# Success rate per source (account aggregation)
echo "--- Account Aggregation per Source ---"
echo "$EVENTS" | jq '
  [ .[] | select(.action | startswith("SOURCE_ACCOUNT_AGGREGATION")) ] |
  group_by(.attributes.sourceName) | map({
    source: .[0].attributes.sourceName,
    started: [ .[] | select(.status == "STARTED") ] | length,
    passed: [ .[] | select(.status == "PASSED") ] | length,
    failed: [ .[] | select(.status == "FAILED") ] | length
  }) | sort_by(-.failed) | .[] |
  "\(.source): \(.passed)/\(.started) passed, \(.failed) failed"' -r
echo ""

# Success rate per source (entitlement aggregation)
echo "--- Entitlement Aggregation per Source ---"
echo "$EVENTS" | jq '
  [ .[] | select(.action | startswith("SOURCE_ENTITLEMENT_AGGREGATION")) ] |
  group_by(.attributes.sourceName) | map({
    source: .[0].attributes.sourceName,
    started: [ .[] | select(.status == "STARTED") ] | length,
    passed: [ .[] | select(.status == "PASSED") ] | length,
    failed: [ .[] | select(.status == "FAILED") ] | length
  }) | sort_by(-.failed) | .[] |
  "\(.source): \(.passed)/\(.started) passed, \(.failed) failed"' -r
echo ""

# Failing sources details
echo "--- Failing Sources (last errors) ---"
echo "$EVENTS" | jq '
  [ .[] | select(.status == "FAILED") ] |
  group_by(.attributes.sourceName) | map({
    source: .[0].attributes.sourceName,
    sourceId: .[0].attributes.sourceId,
    failures: length,
    lastFailure: (sort_by(.created) | last | .created),
    actions: [.[].action] | unique
  }) | sort_by(-.failures)'
echo ""

echo "============================================"
echo " Report complete"
echo "============================================"
