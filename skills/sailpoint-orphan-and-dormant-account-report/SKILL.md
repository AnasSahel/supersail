---
name: sailpoint-orphan-and-dormant-account-report
description: Detect and report orphan (uncorrelated) accounts, dormant accounts, stale accounts, and cleanup candidates in SailPoint Identity Security Cloud using the sail CLI. Use this skill when the user asks about orphan accounts, uncorrelated accounts, stale accounts, dormant accounts, inactive accounts, unused accounts, account cleanup, account hygiene, account remediation, dead accounts, zombie accounts, accounts with no identity, unlinked accounts, accounts to delete, deprovisioning candidates, or account health checks. Also trigger on phrases like "find orphan accounts", "which accounts aren't correlated", "stale account report", "clean up old accounts", "accounts that should be removed", "show me dormant accounts", "account hygiene audit", or any request about identifying accounts that are orphaned, uncorrelated, inactive, or candidates for cleanup in SailPoint.
---

# SailPoint Orphan & Dormant Account Report

Detect stale accounts, orphan (uncorrelated) accounts, and cleanup candidates across SailPoint Identity Security Cloud sources.

## Prerequisites

- The `sail` CLI must be installed and configured
- Admin permissions on the target ISC tenant

## Workflow

### Step 1: Environment Selection

Before doing anything, show the user which environments are available and ask them to pick one. Operating on the wrong tenant means reporting on the wrong data.

```bash
sail environment list
sail environment show  # show current
```

Present the list and ask: "Which environment should I operate in?" Then switch:

```bash
sail environment use {name}
```

### Step 2: Scope Selection

Ask the user: do you want to scan all sources, a specific source, or a list of sources?

**List all sources:**
```bash
sail api get '/v2025/sources' -q 'limit=100'
```

**Find a source by name:**
```bash
sail api get '/v2025/sources' -q 'filters=name eq "Source Name"'
```

Present sources with their `id`, `name`, `type`, and `healthy` status so the user can select. Save the selected source IDs for the next steps.

### Step 3: Find Orphan Accounts (Uncorrelated)

Orphan accounts are accounts that exist in a source but have no linked identity in ISC. They have `identityId: null` or are flagged as uncorrelated.

**Approach A — Search API:**
```bash
sail api post '/v2025/search' --body '{"indices":["accountactivities"],"query":{"query":"source.id:{sourceId} AND uncorrelated:true"},"queryType":"SAILPOINT"}'
```

**Approach B — Accounts API with in-memory filtering (more reliable):**

Paginate through all accounts for each source and filter for those where `identityId` is null or empty:

```bash
sail api get '/v2025/accounts' -q 'filters=sourceId eq "{sourceId}"' -q 'limit=250' -q 'offset=0'
```

Keep paginating (offset 0, 250, 500, ...) until you get an empty page. Filter results in memory for accounts where `identityId` is `null` or empty string — these are orphan accounts.

For each orphan account, capture: `id`, `name`, `nativeIdentity`, `created`, `modified`, `disabled`, and `sourceId`.

### Step 4: Find Dormant Accounts

Dormant accounts are correlated (they have an identity) but show signs of inactivity. Check for:

1. **Accounts where `disabled` is `false` but the linked identity's lifecycle state is `inactive` or `quit`** — these are active accounts on inactive identities, prime deprovisioning candidates
2. **Accounts that haven't been modified in a long time** — use the `modified` field and compare to today's date. A reasonable threshold is 90 days, but ask the user for their preference.

**Step 4a — Find identities in inactive lifecycle states:**

Use the search API to find identities that are in inactive or quit states:
```bash
sail api post '/v2025/search' --body '{"indices":["identities"],"query":{"query":"lifecycleState:(inactive OR quit OR terminated OR disabled)"},"queryType":"SAILPOINT","sort":["name"]}'
```

Then for each identity found, fetch their accounts:
```bash
sail api get '/v2025/accounts' -q 'filters=identityId eq "{identityId}"' -q 'limit=250'
```

Filter for accounts that are still enabled (`disabled: false`) — these are dormant.

**Step 4b — Find stale accounts by modification date:**

From the paginated account data already retrieved in Step 3, filter for correlated accounts (those with a non-null `identityId`) where the `modified` date is older than the threshold (e.g., 90 days). Calculate `daysSinceModified` from the `modified` field to today.

### Step 5: Generate Report

Present a structured report with the following sections:

---

**Orphan Accounts (Uncorrelated)**

| Source | Account Name | Native Identity | Disabled | Created | Last Modified |
|--------|-------------|-----------------|----------|---------|---------------|

For each orphan, recommend one of:
- **Correlate** — if there's a matching identity that should own this account
- **Disable** — if the account should be kept but deactivated
- **Delete** — if the account is clearly stale and should be removed

---

**Dormant Accounts**

| Source | Account Name | Identity | Lifecycle State | Disabled | Days Since Modified |
|--------|-------------|----------|----------------|----------|-------------------|

For each dormant account, recommend:
- **Review for deprovisioning** — identity is inactive/quit but account is still enabled
- **Monitor** — account is old but identity is still active

---

**Summary**

- Total orphan accounts: X across Y sources
- Total dormant accounts: X across Y sources
- Sources with most orphans: ranked list (source name — count)
- Sources with most dormant accounts: ranked list
- Cleanup priority per source: **High** (>20 orphans or dormant), **Medium** (5-20), **Low** (<5)
- Recommended next steps: prioritized list of actions

---

If the user wants to take action on any accounts (disable, delete, correlate), confirm before proceeding and use the appropriate API endpoints. For disable operations, refer to the `sailpoint-account-status` skill pattern.

## CLI Parsing Notes

- The `sail` CLI prefixes output with a log line: `INFO Making GET/POST request endpoint=...`
- A status line is appended at the end: `Status: 200 OK`
- Strip both before parsing JSON
- Use `-q 'key=value'` for GET query parameters (not inline in the URL)
- Use `--body '{...}'` for POST request bodies
- The `-q` flag only works on GET requests, not POST
- POST body JSON must be passed as a single-line string to `--body`
