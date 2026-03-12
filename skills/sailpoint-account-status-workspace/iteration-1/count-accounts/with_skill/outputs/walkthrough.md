# Walkthrough: "Show me how many accounts are enabled and disabled in the Active Directory source"

This walkthrough follows the `sailpoint-account-status` skill (SKILL.md) step by step, without executing any commands.

---

## Step 1: Environment Selection

The skill says to show available environments and confirm the correct tenant before doing anything else.

**Commands I would run:**

```bash
sail environment list
```

**Expected output:** A list of configured ISC tenants, e.g.:

```
  devacme
  staging
> prodacme
```

Then show the currently active environment:

```bash
sail environment show
```

**Expected output:** Details of the active environment (name, tenant URL, etc.).

**What I would do next:** Present the environment info to the user and ask them to confirm this is the right tenant. If they say it is wrong, I would run:

```bash
sail environment use {correct-name}
```

For this walkthrough, assume the user confirms the active environment is correct.

---

## Step 2: Identify the Source

The user said "Active Directory source," so I have a name to search for. The skill says to look it up by name.

**Command I would run:**

```bash
sail api get '/v2025/sources' -q 'filters=name eq "Active Directory"'
```

**Expected output:** A JSON array containing the matching source(s), e.g.:

```json
[
  {
    "id": "2c91808a7fac1d5e017fb0321c030f9a",
    "name": "Active Directory",
    "type": "Active Directory - Direct",
    "connector": "active-directory",
    ...
  }
]
```

**What I would do next:** Extract the `id` field from the response. If the array is empty (no exact match), I would fall back to listing all sources so the user can pick the right one:

```bash
sail api get '/v2025/sources' -q 'limit=100'
```

For this walkthrough, assume the source was found and its ID is `2c91808a7fac1d5e017fb0321c030f9a`.

---

## Step 3: List and Count Accounts

The skill explicitly states that the `disabled` field is **not filterable** in the accounts API, so I must paginate through all accounts and count enabled vs. disabled in memory. The skill specifies `limit=250` per page.

**First page:**

```bash
sail api get '/v2025/accounts' -q 'filters=sourceId eq "2c91808a7fac1d5e017fb0321c030f9a"' -q 'limit=250' -q 'offset=0'
```

**Expected output:** A JSON array of up to 250 account objects. Each account has a `disabled` boolean field, e.g.:

```json
[
  {
    "id": "acc-001",
    "name": "jsmith",
    "disabled": false,
    ...
  },
  {
    "id": "acc-002",
    "name": "jdoe",
    "disabled": true,
    ...
  }
]
```

**Second page (offset 250):**

```bash
sail api get '/v2025/accounts' -q 'filters=sourceId eq "2c91808a7fac1d5e017fb0321c030f9a"' -q 'limit=250' -q 'offset=250'
```

**Continue paginating** (offset 500, 750, 1000, ...) until the API returns an empty array `[]`, which signals there are no more accounts.

**In-memory counting:** For each page of results, I would iterate through the account objects and:
- If `disabled` is `false`, increment the "Enabled" counter.
- If `disabled` is `true`, increment the "Disabled" counter.

For example, assume after paginating through 3 pages (559 total accounts), I get:
- Page 1 (offset 0): 250 accounts returned
- Page 2 (offset 250): 250 accounts returned
- Page 3 (offset 500): 59 accounts returned
- Page 4 (offset 750): 0 accounts returned (empty array -- stop here)

---

## Present the Summary

The skill prescribes a specific table format for reporting. After counting all accounts across all pages, I would present:

| Status | Count |
|--------|-------|
| Enabled | 412 |
| Disabled | 147 |
| **Total** | **559** |

(These numbers are hypothetical for illustration.)

---

## Steps 4-6: Not Applicable

The user only asked to **see** how many accounts are enabled and disabled. They did not ask to change any account states. The skill workflow continues to Steps 4 (Select Accounts), 5 (Execute enable/disable), and 6 (Verify), but none of those steps are triggered by this request.

If the user followed up with something like "disable all enabled accounts," I would continue to Step 4 and beyond.

---

## Summary of Commands

In total, for this request, I would run:

1. `sail environment list` -- show available tenants
2. `sail environment show` -- confirm active tenant
3. `sail api get '/v2025/sources' -q 'filters=name eq "Active Directory"'` -- find the source ID
4. `sail api get '/v2025/accounts' -q 'filters=sourceId eq "{sourceId}"' -q 'limit=250' -q 'offset=0'` -- first page of accounts
5. Repeat the accounts call with offset 250, 500, 750, ... until an empty page is returned
6. Count `disabled: true` vs `disabled: false` across all pages and present the summary table
