---
name: sailpoint-access-request-investigator
description: Investigate, diagnose, and explain why a SailPoint access request is blocked, stuck, failing, pending, or not completing. Use this skill whenever the user asks about an access request that isn't going through, wants to know why a request is stuck, asks about approval status, provisioning failures, access request errors, pending requests, blocked requests, denied requests, or anything related to the lifecycle of an access request in SailPoint Identity Security Cloud. Also trigger when the user says things like "why is my access request stuck", "where is my request blocked", "request won't complete", "who needs to approve", "provisioning failed", "access request error", "show me pending requests", "what happened to my request", "request is taking forever", "can't get access", or "request status".
---

# SailPoint Access Request Investigator

Explain exactly where an access request is blocked — approval, workflow, provisioning, or source-side failure — and offer resolution options.

## Prerequisites

- The `sail` CLI must be installed and configured
- The user needs appropriate admin permissions to view and manage access requests

## Workflow

### Step 1: Environment Selection

Before doing anything, confirm which SailPoint environment to operate in.

```bash
sail environment list
sail environment show  # show current
```

Present the list and ask: "Which environment should I operate in?" Then switch if needed:

```bash
sail environment use {name}
```

### Step 2: Find the Request

The user might provide a request ID, an identity name, or just say "show me pending requests". Fetch access request statuses:

```bash
sail api get '/v2025/access-request-status'
```

The response is a JSON array. The CLI prefixes a log line (`INFO Making GET request...`) and suffixes a status line — strip both before parsing JSON.

You can also filter with query params:

```bash
sail api get '/v2025/access-request-status' -q 'requested-for=<identity-id>'
sail api get '/v2025/access-request-status' -q 'regarding-identity=<identity-id>'
```

Filter the results by state to find problematic requests:
- `EXECUTING` — in progress, possibly stuck
- `PENDING` — waiting for action
- `ERROR` — failed
- `NOT_ALL_ITEMS_PROVISIONED` — partially failed

Present a summary of matching requests: Name, Type, State, Requested For, Created date, and how long it has been in this state.

If the user provided an identity name but you need an ID, search for the identity first:

```bash
sail api get '/v2025/public-identities' -q 'filters=name eq "<name>"'
```

### Step 3: Trace the Request Lifecycle

For each request (or the one the user picks), examine the `accessRequestPhases` array. Each phase has: `name`, `state`, `started`, `finished`.

**APPROVAL_PHASE:**
- `state: "EXECUTING"` — waiting for approval, request is blocked here
- `state: "COMPLETED"` — approval granted, moved past this phase
- Check `approvalDetails` for individual approver statuses:
  - Who needs to approve (name, identity)
  - Whether each approver has acted
  - Whether the approval is a single-approver or multi-approver scheme

**PROVISIONING_PHASE:**
- `state: "EXECUTING"` — provisioning is in progress
- `state: "COMPLETED"` — provisioning finished
- If `started` has a date but `finished` is `null`, provisioning is hung — this is a stuck provisioning scenario

Key fields on the request object:
- `state` — overall request state: EXECUTING, PENDING, REQUEST_COMPLETED, NOT_ALL_ITEMS_PROVISIONED, ERROR
- `cancelable` — true/false, determines which cancel/close path is available
- `errorMessages` — array of error details (may be null)
- `accountActivityItemId` — used for standard cancel (maps to `accountActivityId` in the cancel body)
- `accessRequestId` — used for force-close (maps to `accessRequestIds` array in the close body)
- `requestedAccounts` — source name and account info, helps identify source-side failures

### Step 4: Determine Blockage Point

Present a clear, specific diagnosis to the user:

- **"Blocked at APPROVAL"** — "Waiting for {approver name} to approve. The request has been pending approval for {N} days."
- **"Blocked at PROVISIONING"** — "{source name} failed with: {error message from errorMessages}."
- **"Stuck — hung provisioning"** — "Provisioning started {N} days ago with no response from the target source. The connector may have timed out or lost connection."
- **"Failed"** — "The request failed with error: {error explanation}. Suggested fix: {actionable advice based on the error}."
- **"Partially failed"** — "State is NOT_ALL_ITEMS_PROVISIONED. Some items were provisioned but {item} failed on {source} with: {error}."

Always include:
- Which phase is the bottleneck
- How long the request has been in this state
- The specific error message if one exists
- The target source and account if relevant

### Step 5: Resolution Options

Based on the diagnosis, present resolution options. **Always ask for user confirmation before taking action.**

**Approval blocked:**
- Identify the approver by name
- Suggest the user contact the approver directly
- Mention that approval reassignment may be possible through the admin UI

**Provisioning stuck, cancelable:true — Standard Cancel:**

```bash
sail api post '/v2025/access-requests/cancel' \
  --body '{"accountActivityId":"<accountActivityItemId>","comment":"<reason>"}'
```

Note: the body field is `accountActivityId` and the value comes from the request's `accountActivityItemId` field. The body uses `comment` (not `message`).

**Provisioning stuck, cancelable:false — Force Close:**

The standard cancel endpoint will reject with "Invalid request in current state". Use the beta close endpoint:

```bash
sail api post '/beta/access-requests/close' \
  --body '{"accessRequestIds":["<accessRequestId>"],"message":"<reason>"}'
```

Note: the body field is `accessRequestIds` (an array) and the value comes from the request's `accessRequestId` field. The body uses `message` (not `comment`). This is a **beta** endpoint.

**Failed request:**
- Explain the error in plain language
- Suggest fixing the root cause (missing attribute, connector config, source permissions) before re-submitting
- If the failed request is stuck in ERROR state and won't clear, offer force-close

**After any resolution action:** Report the result (job ID, status, errors). Suggest the user refresh the admin UI to confirm, and remind them they can re-submit the access request once the underlying issue is resolved.

## Common Patterns

- **Hung provisioning with no error**: Connector timed out or lost connection — force-close is the only option
- **Approval stuck for days**: The approver may be out of office or the approval scheme may be misconfigured
- **"IdentityRequest already exists"**: A retry was attempted while the original was stuck — close the original first
- **Null identity / missing attributes**: A before-operation rule failed because identity data was incomplete
- **Source-side errors (SQL, LDAP, etc.)**: The connector reached the source but the operation failed — fix the source-side issue first
- **"No configuration found for 'Remove Entitlement'"**: The connector doesn't have a remove operation configured
