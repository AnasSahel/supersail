# Walkthrough: "Disable all accounts matching X_* in Active Directory"

This walkthrough follows the `sailpoint-account-status` skill step by step, showing the exact commands that would be run, expected responses, and decision points.

---

## Step 1: Environment Selection

Before touching anything, confirm we are targeting the correct tenant.

**Commands:**

```bash
sail environment list
```

**Expected output** (example):

```
+----------+-----------------------------------------+
| Name     | URL                                     |
+----------+-----------------------------------------+
| prod     | https://acme.api.identitynow.com        |
| sandbox  | https://acme-sb.api.identitynow.com     |
+----------+-----------------------------------------+
```

```bash
sail environment show
```

**Expected output:**

```
Active environment: prod
Tenant URL: https://acme.api.identitynow.com
```

**Decision point:** Ask the user to confirm the environment. If they want a different one:

```bash
sail environment use sandbox
```

We do not proceed until the user explicitly confirms the environment.

---

## Step 2: Identify the Source

The user said "Active Directory", but we need the exact source name and its `id` in ISC. Search for it:

```bash
sail api get '/v2025/sources' -q 'filters=name co "Active Directory"'
```

**Expected output** (example):

```json
[
  {
    "id": "2c91808a7e234abc123456def",
    "name": "Active Directory",
    "type": "Active Directory - Direct",
    "authoritative": false,
    "connectorAttributes": { ... }
  }
]
```

If multiple sources match (e.g., "Active Directory - Corp", "Active Directory - Lab"), present the list and ask the user to pick one.

**Saved value:** `sourceId = "2c91808a7e234abc123456def"`

---

## Step 3: List and Count All Accounts

The `disabled` field is not filterable via the API, so we must paginate through all accounts for this source and count in memory.

**Page 1:**

```bash
sail api get '/v2025/accounts' -q 'filters=sourceId eq "2c91808a7e234abc123456def"' -q 'limit=250' -q 'offset=0'
```

**Expected output:** A JSON array of up to 250 account objects, each containing fields like:

```json
{
  "id": "acc-uuid-001",
  "name": "jsmith",
  "disabled": false,
  "sourceId": "2c91808a7e234abc123456def",
  "attributes": { ... }
}
```

**Page 2:**

```bash
sail api get '/v2025/accounts' -q 'filters=sourceId eq "2c91808a7e234abc123456def"' -q 'limit=250' -q 'offset=250'
```

Continue paginating (offset 500, 750, ...) until an empty array `[]` is returned.

**Present summary to user:**

| Status | Count |
|--------|-------|
| Enabled | 480 |
| Disabled | 79 |
| **Total** | **559** |

---

## Step 4: Select Accounts (Pattern Filtering)

The user wants accounts matching the pattern `X_*`. This means account names that start with `X_`.

Since the API does not support pattern filtering, we filter the full account list in memory. For each account fetched in Step 3, check if `account.name` starts with `X_` (matching the glob pattern `X_*`).

**Matched accounts** (example):

| # | Account Name | Current Status |
|---|-------------|----------------|
| 1 | X_svc_backup | Enabled |
| 2 | X_svc_deploy | Enabled |
| 3 | X_test_user1 | Enabled |
| 4 | X_test_user2 | Enabled |
| 5 | X_batch_proc | Enabled |
| 6 | X_migration  | Disabled |
| ... | ... | ... |

**Pre-filter:** Remove any accounts that are already disabled, since we only need to disable enabled accounts. Attempting to disable an already-disabled account may error or waste API calls.

Suppose after filtering out already-disabled accounts we have 23 enabled accounts matching `X_*`.

**Confirmation (required -- more than 10 accounts):**

> "This will disable **23 accounts** in **Active Directory**. Are you sure?"

We stop and wait for the user to confirm before proceeding. The full list of matched account names is shown so the user can review.

---

## Step 5: Execute (Bulk Disable)

After the user confirms, iterate through all 23 matched account IDs and call the disable endpoint for each one.

**For each account:**

```bash
sail api post '/v2025/accounts/acc-uuid-001/disable' --body '{}'
```

**Expected response (202 Accepted):**

```json
{"id": "task-uuid-abc123"}
```

Store each returned task ID for verification.

**Progress reporting** (every 50 accounts, or at completion if fewer than 50):

```
Progress: 23/23 (success=23, errors=0)
```

If there were more accounts (say 559), reporting would look like:

```
Progress: 50/559 (success=50, errors=0)
Progress: 100/559 (success=100, errors=0)
Progress: 150/559 (success=148, errors=2)
...
```

**Error handling during execution:** If any individual call fails, log the account name and error, increment the error counter, and continue with the remaining accounts. Do not abort the entire batch.

---

## Step 6: Verify

Spot-check a sample of the returned task IDs to confirm operations completed successfully. For 23 accounts, checking 3-5 is reasonable.

```bash
sail api get '/v2025/task-status/task-uuid-abc123'
```

**Expected response:**

```json
{
  "id": "task-uuid-abc123",
  "completionStatus": "SUCCESS",
  "target": {
    "name": "X_svc_backup"
  },
  "messages": []
}
```

If `completionStatus` is `null`, the task is still running. Wait a few seconds and check again:

```bash
sail api get '/v2025/task-status/task-uuid-abc123'
```

If `completionStatus` is `ERROR`, inspect the `messages` field. A common error is:

```
Failed to update attribute password - New password violates password-history or constraints
```

This means the BeforeProvisioning Rule generated a password that collides with AD password history. The account remains enabled. Report this to the user as a known issue -- the account will need to be retried or handled manually.

**Final report to user:**

```
Bulk disable complete for Active Directory.

  Pattern:    X_*
  Attempted:  23
  Succeeded:  22
  Failed:     1

Failed accounts:
  - X_svc_deploy: password history violation (account remains enabled)
```

---

## Summary of Key Safeguards

1. **Environment confirmation** -- always verify the tenant before any operation.
2. **Source identification** -- resolve the exact source by name and confirm with the user if ambiguous.
3. **In-memory filtering** -- the API does not support pattern or disabled-state filtering, so all filtering happens client-side after full pagination.
4. **Pre-filter by current state** -- skip accounts already in the target state to avoid unnecessary API calls and potential errors.
5. **Confirmation before bulk operations** -- any operation affecting more than 10 accounts requires explicit user approval, with the full account list visible.
6. **Progress reporting** -- report every 50 accounts so the user knows the operation is proceeding.
7. **Spot-check verification** -- check a sample of task statuses rather than all of them, unless errors were detected during submission.
8. **Error resilience** -- individual failures do not abort the batch; errors are logged and reported at the end.
