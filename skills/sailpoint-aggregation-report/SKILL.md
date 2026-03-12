---
name: aggregation-report
description: Generate a SailPoint source aggregation health report. Use this skill whenever the user asks about aggregation status, source health, source failures, aggregation errors, or wants a summary of how their SailPoint sources are performing. Also trigger when they mention "aggregation report", "source report", "what's failing", "aggregation issues", or anything about monitoring source aggregation in Identity Security Cloud (ISC).
---

# Aggregation Report

Generate a health report on SailPoint ISC source aggregations by querying the Search API for `source_management` events.

## How it works

The report queries aggregation events from the ISC Search API and breaks them down into actionable sections. This gives a quick picture of which sources are healthy and which need attention.

## Running the report

Execute the bundled script at `scripts/report.sh` (located in the same directory as this SKILL.md). It accepts an optional time period argument — the default is `1w` (one week).

```bash
bash <skill-dir>/scripts/report.sh         # last 7 days
bash <skill-dir>/scripts/report.sh 1d      # last 24 hours
bash <skill-dir>/scripts/report.sh 30d     # last 30 days
```

## Important: `sail api` output quirk

The `sail` CLI sends JSON response bodies to **stderr**, not stdout. It also mixes in log lines (timestamped) and a `Status:` line. The bundled script handles this, but if you need to run `sail api` commands directly, always filter like this:

```bash
sail api get "/v2025/sources" 2>&1 | grep -v '^[0-9]\{4\}/' | grep -v '^Status:' | grep -v '^Error:'
```

For POST requests, `sail api post` requires the `--body` flag (even if the body is empty):

```bash
sail api post /v2025/search --body '{"indices": ["events"], "query": {"query": "..."}}' 2>&1 | grep -v ...
```

## Report sections

The report output contains four sections:

1. **Event Summary** — Total counts by action type (started, passed, failed) to get a high-level view
2. **Account Aggregation per Source** — Success rate for each source's account aggregation, sorted by failures first so problem sources are immediately visible
3. **Entitlement Aggregation per Source** — Same breakdown for entitlement aggregation
4. **Failing Sources** — Details on every source that had failures: source ID, failure count, last failure timestamp, and which aggregation types failed. This is the section to focus on for troubleshooting

## Interpreting the results

- A source showing `0/N passed, N failed` is completely broken and needs immediate attention (likely a connector config issue — missing credentials, unreachable endpoint, etc.)
- Occasional failures mixed with passes may indicate intermittent connectivity or timeouts
- Sources with `[gov-async-ent]` prefix are governance-triggered entitlement aggregations
- The search API returns events up to 90 days old

## Follow-up actions

After identifying failing sources, common next steps:

- Test connector health: `sail api post /v2025/sources/<sourceId>/connector/check-connection --body '{}'`
- Check source config: `sail api get /v2025/sources/<sourceId>`
- Check source health: `sail api get /v2025/sources/<sourceId>/source-health`
