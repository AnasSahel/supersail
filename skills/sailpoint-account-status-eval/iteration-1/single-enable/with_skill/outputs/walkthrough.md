# Walkthrough: "Enable back the account X_sylran"

Following the skill at `skills/sailpoint-account-status/SKILL.md` step by step.

---

## Step 1: Environment Selection

The skill says to show available environments and ask the user to pick one before doing anything else.

**Commands I would run:**

```bash
sail environment list
sail environment show
```

**Expected output:** A list of configured tenants (e.g., `dev`, `staging`, `prod`) and which one is currently active.

**Action:** Present the list to the user and ask them to confirm the active environment is correct, or tell me which one to switch to. If they say to switch:

```bash
sail environment use {name}
```

I would not proceed until the user confirms the environment.

---

## Step 2: Identify the Source

The user said "X_sylran" -- this looks like an account name, not a source name. The `X_` prefix hints at a naming convention but does not tell me which source the account belongs to. The skill says if the user didn't specify a source, list available sources so they can pick.

**Command I would run:**

```bash
sail api get '/v2025/sources' -q 'limit=100'
```

**Expected output:** A JSON array of source objects, each with `id`, `name`, `type`, etc.

**Action:** Present the source names to the user and ask which source contains the `X_sylran` account. Suppose the user says "Active Directory" and its `id` is `2c91808876abcdef12345678`.

---

## Step 3: List and Count Accounts

The skill says to paginate through all accounts in the source, since `disabled` is not filterable. However, for this request the user wants a specific account by name. I still need to find it.

I would search for the account. The accounts API supports filtering by `name`, so I can look it up directly rather than paginating through everything:

**Command I would run (first page):**

```bash
sail api get '/v2025/accounts' -q 'filters=sourceId eq "2c91808876abcdef12345678" and name eq "X_sylran"' -q 'limit=250' -q 'offset=0'
```

**Expected output:** A JSON array containing 0 or 1 account objects. If found, each account has fields like:
```json
[
  {
    "id": "2c91808a8bcd1234ef567890",
    "name": "X_sylran",
    "disabled": true,
    "sourceId": "2c91808876abcdef12345678",
    "identityId": "...",
    "nativeIdentity": "CN=sylran,OU=Users,DC=example,DC=com",
    ...
  }
]
```

**What I am looking for:**
- The account `id` -- needed for the enable call.
- The `disabled` field -- should be `true` since the user wants to "enable it back". If it is already `false` (enabled), I would tell the user the account is already enabled and ask if they still want to proceed.

If the filter by `name` returns nothing, I would fall back to paginating all accounts and searching in memory for a name matching "X_sylran" (case-insensitive, partial match).

**Summary I would present:**

> Found account **X_sylran** in source **Active Directory**. It is currently **disabled**. Ready to enable it.

---

## Step 4: Select Accounts

This is a single-account operation, so no pattern matching or bulk confirmation is needed. The skill says bulk confirmation is only required for more than 10 accounts.

Since this is a single account, I would confirm briefly:

> I will enable the account **X_sylran** (id: `2c91808a8bcd1234ef567890`) in **Active Directory**. Proceeding.

---

## Step 5: Execute

The skill says to enable an account using:

**Command I would run:**

```bash
sail api post '/v2025/accounts/2c91808a8bcd1234ef567890/enable' --body '{}'
```

**Expected output:** HTTP `202 Accepted` with a task ID:
```json
{
  "id": "a]b1c2d3-e4f5-6789-abcd-ef0123456789"
}
```

**What could go wrong:**
- If the account is already enabled, the API may return an error or silently succeed.
- Network/permission errors would surface here.

---

## Step 6: Verify

The skill says to check the task status using the returned task ID.

**Command I would run:**

```bash
sail api get '/v2025/task-status/ab1c2d3-e4f5-6789-abcd-ef0123456789'
```

**Expected output:**
```json
{
  "completionStatus": "SUCCESS",
  "target": {
    "name": "sylran"
  },
  "messages": []
}
```

**What I am checking:**
- `completionStatus` is `SUCCESS` -- the enable operation completed.
- If `completionStatus` is `null`, the task is still running. I would wait a few seconds and run the same command again.
- If `completionStatus` is `ERROR`, I would look at the `messages` array for details and report the error to the user.

**Final response to the user:**

> The account **X_sylran** has been successfully enabled in **Active Directory**. The task completed with status **SUCCESS**.

---

## Summary of All Commands in Order

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `sail environment list` | Show available environments |
| 1 | `sail environment show` | Show currently active environment |
| 1 | `sail environment use {name}` | Switch environment (if needed) |
| 2 | `sail api get '/v2025/sources' -q 'limit=100'` | List all sources so user can pick |
| 3 | `sail api get '/v2025/accounts' -q 'filters=sourceId eq "{sourceId}" and name eq "X_sylran"' -q 'limit=250' -q 'offset=0'` | Find the specific account |
| 5 | `sail api post '/v2025/accounts/{accountId}/enable' --body '{}'` | Enable the account |
| 6 | `sail api get '/v2025/task-status/{taskId}'` | Verify the enable task completed |

Total API calls for this single-enable scenario: 4 (environment, sources, account lookup, enable) + 1 verification = 5 calls minimum.
