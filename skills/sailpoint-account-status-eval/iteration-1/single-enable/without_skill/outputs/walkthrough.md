# Walkthrough: Enable Back the Account "X_sylran"

## Goal

Re-enable a disabled account with the native identity / account name `X_sylran` in SailPoint Identity Security Cloud using the `sail` CLI and the ISC API.

---

## Step-by-Step Plan

### Step 1 — Verify the Active Environment

Before touching anything, confirm that the CLI is pointed at the correct tenant.

```bash
sail environment show
```

**Expected output:** The active environment's base URL, client ID, and tenant name. I would verify this is the production or target tenant where `X_sylran` lives.

---

### Step 2 — Search for the Account

I need the account's internal ID (a UUID) to issue the enable call. The account name `X_sylran` is a native identity or account name, so I would search for it.

```bash
sail search query --query "name:X_sylran" --indices accounts
```

**Expected output:** One or more account objects returned as JSON. Each result would contain fields like:

- `id` — the internal account UUID (e.g., `2c91808a7e2b3c4d...`)
- `name` — should match `X_sylran`
- `nativeIdentity` — the account's identifier on the source system
- `sourceId` — the source this account belongs to
- `disabled` — should be `true` if the account is currently disabled
- `identityId` — the identity (person) who owns the account

I would note the `id` value for the next steps. If multiple results come back, I would pick the one whose `name` or `nativeIdentity` exactly matches `X_sylran`.

If the `sail search` command does not support the `--indices` flag or returns unexpected results, the alternative is a direct API call:

```bash
sail rest get "/v2025/accounts?filters=name eq \"X_sylran\""
```

---

### Step 3 — Confirm the Account Is Currently Disabled

From the search results in Step 2, I would inspect the `disabled` field. If it is `true`, the account is indeed disabled and eligible to be re-enabled. If it is already `false`, no action is needed.

I could also fetch the account directly by ID to double-check:

```bash
sail rest get "/v2025/accounts/{account-id}"
```

**Expected output:** A full account object with `"disabled": true`.

---

### Step 4 — Enable the Account

SailPoint ISC exposes an account enable/disable action via the Accounts API. The endpoint is:

```
POST /v2025/accounts/{account-id}/enable
```

Using the sail CLI:

```bash
sail rest post "/v2025/accounts/{account-id}/enable"
```

Replace `{account-id}` with the UUID obtained in Step 2.

**Expected output:** A `202 Accepted` response or a task result object. SailPoint processes enable/disable requests asynchronously, so the response typically contains a task ID or a pending status. Example:

```json
{
  "type": "TASK_RESULT",
  "id": "2c91808a...",
  "name": "Cloud Account Enable"
}
```

---

### Step 5 — Verify the Account Is Now Enabled

Wait a few seconds for the provisioning to complete, then confirm the account state has changed.

```bash
sail rest get "/v2025/accounts/{account-id}"
```

**Expected output:** The account object with `"disabled": false`, confirming the account has been re-enabled.

Alternatively, search again:

```bash
sail search query --query "name:X_sylran" --indices accounts
```

And verify the `disabled` field is now `false`.

---

### Step 6 — (Optional) Check the Task Status

If the enable request returned a task result ID, I could check whether it completed successfully:

```bash
sail rest get "/v2025/task-status/{task-id}"
```

**Expected output:** A task object with `"completionStatus": "SUCCESS"`.

---

## Summary of Commands

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `sail environment show` | Confirm target tenant |
| 2 | `sail search query --query "name:X_sylran" --indices accounts` | Find the account and get its UUID |
| 3 | `sail rest get "/v2025/accounts/{account-id}"` | Confirm the account is disabled |
| 4 | `sail rest post "/v2025/accounts/{account-id}/enable"` | Enable the account |
| 5 | `sail rest get "/v2025/accounts/{account-id}"` | Verify the account is now enabled |
| 6 | `sail rest get "/v2025/task-status/{task-id}"` | (Optional) Check provisioning task status |

## Key Considerations

- **Governance:** Depending on the tenant's configuration, enabling an account might require approval through an access request or governance workflow. If the direct API call is rejected with a 403 or policy error, the enable would need to go through the proper request channel instead.
- **Source connectivity:** The source (Active Directory, SAP, etc.) that hosts this account must be reachable by its Virtual Appliance cluster for the provisioning action to succeed. If the VA is down, the task will fail.
- **Audit trail:** The enable action will be logged in the ISC audit events. No additional audit step is needed, but it is good practice to note why the account was re-enabled.
- **`sail rest` subcommand:** If the installed version of the `sail` CLI does not have a `rest` subcommand for raw API calls, the equivalent can be done with `curl` using the tenant's OAuth token, or by using the `sail api` subcommand if available.
