---
name: sailpoint-provisioning-failure-triage
description: Explain why provisioning failed in SailPoint Identity Security Cloud. Use this skill whenever the user mentions provisioning failures, provisioning errors, failed account creation, failed account updates, connector errors, rule exceptions, target system rejections, or any provisioning-related issue. Also trigger on phrases like "why did provisioning fail", "provisioning error", "account creation failed", "modify operation failed", "connector timeout", "BeforeProvisioning rule error", "password policy violation", "duplicate account error", "missing attribute", "operation not configured", "provisioning stuck", "provisioning not completing", "access request failed to provision", "entitlement not granted", "role provisioning error", "source provisioning issue", "what went wrong with provisioning", "show me recent failures", or any mention of failed, broken, or erroring provisioning in SailPoint ISC.
---

# SailPoint Provisioning Failure Triage

Diagnose why provisioning failed by identifying the source, operation, error message, likely root cause, and suggested fix.

## Prerequisites

- The `sail` CLI must be installed and configured
- Admin permissions on the target ISC tenant

## Workflow

### Step 1: Environment Selection

Before doing anything, show the user which environments are available and ask them to pick one. Operating on the wrong tenant means investigating the wrong failures.

```bash
sail environment list
sail environment show  # show current
```

Present the list and ask: "Which environment should I operate in?" Then switch:

```bash
sail environment use {name}
```

### Step 2: Find Failed Provisioning

The user may provide an identity name, an access request ID, or just say "show me recent failures". Use the appropriate approach:

**Approach A — Search for recent failures (default):**

```bash
sail api post '/v2025/search' --body '{"indices":["accountactivities"],"query":{"query":"completionStatus:ERROR"},"queryType":"SAILPOINT","sort":["modified"],"searchAfter":[]}'
```

This returns account activity objects with `completionStatus: ERROR`. Each object contains:
- `requester` and `target` identities
- `items[]` — the individual provisioning operations, each with its own `name` (operation), `application` (source name), and error details
- `created` / `modified` timestamps

To narrow by identity:
```bash
sail api post '/v2025/search' --body '{"indices":["accountactivities"],"query":{"query":"completionStatus:ERROR AND target.name:\"John Doe\""},"queryType":"SAILPOINT","sort":["modified"],"searchAfter":[]}'
```

**Approach B — From an access request ID:**

```bash
sail api get '/v2025/access-request-status' -q 'filters=accessRequestId eq "{requestId}"'
```

Check the `errorMessages` field and `accessRequestPhases` for the provisioning phase state. If the request has an `accountActivityItemId`, fetch the activity:

```bash
sail api post '/v2025/search' --body '{"indices":["accountactivities"],"query":{"query":"id:{accountActivityItemId}"},"queryType":"SAILPOINT"}'
```

**Approach C — Check a specific task:**

```bash
sail api get '/v2025/task-status/{taskId}'
```

Key fields: `completionStatus`, `messages[].localizedText.message`, `target.name`.

### Step 3: Diagnose

Parse the error messages from the account activity items and categorize into root cause buckets:

**Connector errors:**
- Connection timeout or refused — the connector cannot reach the target system
- Authentication failure — connector credentials are invalid or expired
- SSL/TLS errors — certificate issues between connector and target

**Rule failures:**
- `java.lang.Exception` or `BSF` in the message — a BeforeProvisioning or AfterProvisioning rule threw an exception
- `NullPointerException` in rule context — the rule tried to access data that doesn't exist on the identity or account

**Target system errors:**
- `New password violates password-history` — AD password policy rejected the password (common when BeforeProvisioning rule scrambles passwords on disable)
- `Fiche deja existante` or similar duplicate messages — the account already exists in the target system
- SQL syntax errors — special characters in attribute values broke a database query
- HTTP 400 — bad request to a web-service target (check attribute values)
- HTTP 401/403 — target system rejected the connector's credentials or permissions
- HTTP 500 — target system internal error (not a SailPoint problem)

**Configuration errors:**
- `No configuration found for 'Remove Entitlement'` (or Create, Modify, Delete, Enable, Disable) — the connector does not have that operation configured
- `userIdentity is null` — the identity could not be resolved in the provisioning plan
- `firstName attribute is missing` (or any required attribute) — a required attribute is not mapped in the source schema or the identity doesn't have a value for it
- Missing provisioning policy — the source doesn't have a provisioning policy for the operation type

**Workflow / request errors:**
- `IdentityRequest already exists` — a duplicate request was submitted while a previous one is still processing; the previous request may be stuck
- `ValidationException` — the request payload failed validation before provisioning started

### Step 4: Report

Present findings grouped by source. For each failure:

| Field | Value |
|-------|-------|
| **Source** | {source name} ({source type}) |
| **Operation** | Create / Modify / Delete / Enable / Disable |
| **Target identity** | {identity name} |
| **Error message** | {human-readable error, cleaned up} |
| **Root cause** | {category}: {explanation} |
| **Suggested fix** | {actionable recommendation} |

If there are multiple failures, group them by source and summarize patterns:
- "5 out of 8 failures on Active Directory are password-history violations during disable"
- "All failures on ServiceNow are HTTP 401 — likely an expired service account"

Always include:
1. The total count of failures found
2. The time range of the failures
3. Whether the failures are one-off or a pattern

### Common Error Patterns

These are real-world error messages and their meanings:

| Error message | Root cause | Fix |
|---------------|------------|-----|
| `Failed to update attribute password - New password violates password-history or constraints` | AD password policy rejects the scrambled password during disable | Adjust the BeforeProvisioning rule to generate passwords that meet AD history requirements, or configure a longer/more random password |
| `userIdentity is null` | Identity not resolved in provisioning plan | Check identity correlation — the account may not be correlated to an identity, or the identity was deleted |
| `Fiche deja existante` | Duplicate account in target system | The account already exists — check if it was created manually or by another process. Reconcile or delete the duplicate |
| `No configuration found for 'Remove Entitlement'` | Missing operation in connector configuration | Add the Remove Entitlement operation to the source's connector configuration |
| `IdentityRequest already exists for identity` | Duplicate request while previous is stuck | Find and close the stuck request first (use the stuck-requests skill), then retry |
| `firstName attribute is missing` | Required attribute not mapped or empty | Check the identity's attributes and the source's attribute mapping — ensure the required field has a value |
| `java.lang.Exception: exception from BSF` | BeforeProvisioning or AfterProvisioning rule threw an exception | Check the rule source code for the failing source — look at the specific line in the stack trace |
| `Connection refused` / `Connection timed out` | Connector cannot reach target system | Check network connectivity, firewall rules, and VA health for the source's cluster |
| `HTTP 401 Unauthorized` | Target system credentials expired | Rotate the service account credentials in the source configuration |

## sail CLI Notes

- The `sail api` commands prefix output with a log line: `INFO Making GET/POST request endpoint=...`
- Status line is appended: `Status: 200 OK`
- Strip both before parsing JSON
- Use `-q 'key=value'` for query parameters on GET requests only
- Use `--body '{...}'` for POST request bodies
- The `-q` flag does NOT work on POST requests — put everything in the `--body` JSON
- For search, always use `POST /v2025/search` with the body containing `indices`, `query`, and `queryType`
