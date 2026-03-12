---
name: sailpoint-account-status
description: Enable or disable accounts in a SailPoint ISC source using the sail CLI. Use this skill whenever the user wants to disable accounts, enable accounts, toggle account status, bulk disable/enable, or manage account states in SailPoint Identity Security Cloud. Also trigger on phrases like "disable all accounts", "re-enable accounts", "turn off accounts in AD", "lock accounts in a source", or any request about changing account enabled/disabled status in SailPoint — even if they just say "disable it" or "enable them back".
---

# SailPoint Account Status

Enable or disable accounts in a SailPoint ISC source — from a single account to bulk operations with filtering.

## Prerequisites

- The `sail` CLI must be installed and configured
- Admin permissions on the target ISC tenant

## Workflow

### Step 1: Environment Selection

Show available environments and ask the user to pick one before doing anything else. Operating on the wrong tenant is a costly mistake.

```bash
sail environment list
sail environment show
sail environment use {name}
```

### Step 2: Identify the Source

If the user didn't specify a source, list available sources so they can pick:

```bash
sail api get '/v2025/sources' -q 'limit=100'
```

If they gave a name, look it up:

```bash
sail api get '/v2025/sources' -q 'filters=name eq "Source Name"'
```

Save the `id` from the response — you'll need it for all account queries.

### Step 3: List and Count Accounts

The `disabled` field is **not filterable** in the accounts API. Paginate through all accounts and count in memory. Use `limit=250` per page:

```bash
sail api get '/v2025/accounts' -q 'filters=sourceId eq "{sourceId}"' -q 'limit=250' -q 'offset=0'
```

Keep paginating (offset 0, 250, 500, ...) until you get an empty page.

Present the user with a summary:

| Status | Count |
|--------|-------|
| Enabled | X |
| Disabled | Y |
| **Total** | **Z** |

### Step 4: Select Accounts

The user might want to:
- **Disable/enable a specific account** — look it up by name
- **Disable/enable accounts matching a pattern** — filter by name pattern (e.g., `X_*`, `*.test`)
- **Disable/enable all** enabled (or disabled) accounts

For pattern matching, you have two approaches:
- **In-memory filtering** from the paginated results in Step 3 — simplest, already have the data
- **Search API** — more efficient for large sources or specific patterns. Use the ISC Search API to query accounts directly:
  ```bash
  sail api post '/v2025/search' --body '{"indices":["accountactivities"],"query":{"query":"name:X_* AND source.id:{sourceId}"},"queryType":"SAILPOINT"}'
  ```
  Note: search results may lag behind real-time state by a few minutes after recent changes.

Show the matched accounts and ask for confirmation before proceeding.

For bulk operations (more than 10 accounts), always confirm with the user:
> "This will disable/enable **N accounts** in **{source name}**. Are you sure?"

### Step 5: Execute

**Disable an account:**
```bash
sail api post '/v2025/accounts/{accountId}/disable' --body '{}'
```

**Enable an account:**
```bash
sail api post '/v2025/accounts/{accountId}/enable' --body '{}'
```

Both return `202 Accepted` with a task ID:
```json
{"id": "task-uuid-here"}
```

For bulk operations, iterate through all account IDs and call the endpoint for each one. Report progress every 50 accounts:
```
Progress: 50/559 (success=50, errors=0)
Progress: 100/559 (success=100, errors=0)
```

### Step 6: Verify

Check the task status to confirm the operation completed:

```bash
sail api get '/v2025/task-status/{taskId}'
```

Key fields in the response:
- `completionStatus`: `SUCCESS`, `ERROR`, or `null` (still running)
- `target.name`: the identity affected
- `messages`: error details if failed

If the status is `null`, wait a few seconds and check again.

For bulk operations, spot-check a sample rather than checking all 500+ tasks individually — unless errors were detected during submission.

### Common Errors

**Password history violation on disable:**
```
Failed to update attribute password - New password violates password-history or constraints
```
The BeforeProvisioning Rule scrambles the password when disabling. If the generated password collides with AD's password history, the operation fails. This is account-specific — most accounts will succeed. The affected account remains enabled.

**Account already in target state:**
If you try to disable an already-disabled account (or enable an already-enabled one), the API may return an error or silently succeed. Filter accounts by their current state before operating to avoid unnecessary calls.

## API Quick Reference

See `references/api-endpoints.md` for detailed request/response formats, field descriptions, and sail CLI quirks.
