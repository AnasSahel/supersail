# API Endpoints Reference

## List Access Request Statuses

```
GET /v2025/access-request-status
```

Query parameters (use `sail api get ... -q 'key=value'`):
- `requested-for` — filter by the identity the request was made for
- `regarding-identity` — filter by related identity
- `filters` — SCIM filter expression
- `count` — include total count in response

Returns a JSON array of access request status objects. Key fields per object:

| Field | Description |
|-------|-------------|
| `name` | Name of the requested access (e.g., "VPN Access") |
| `type` | `ACCESS_PROFILE`, `ROLE`, `ENTITLEMENT` |
| `id` | Access item ID (not the request ID) |
| `state` | `EXECUTING`, `PENDING`, `REQUEST_COMPLETED`, `NOT_ALL_ITEMS_PROVISIONED`, `ERROR` |
| `cancelable` | `true` or `false` — determines which cancel path to use |
| `accessRequestId` | The unique request ID — used for force-close |
| `accountActivityItemId` | Activity ID — used for standard cancel |
| `errorMessages` | Array of error arrays, or `null` |
| `accessRequestPhases` | Array of phase objects (see below) |
| `approvalDetails` | Array of approval detail objects (see below) |
| `requester` | `{type, id, name}` |
| `requestedFor` | `{type, id, name}` |
| `requestedAccounts` | Array of `{sourceName, accountId, name}` |
| `created` | ISO timestamp |
| `modified` | ISO timestamp |

### Phase Object (`accessRequestPhases[]`)

| Field | Description |
|-------|-------------|
| `name` | `APPROVAL_PHASE` or `PROVISIONING_PHASE` |
| `state` | `COMPLETED` or `EXECUTING` |
| `started` | ISO timestamp or `null` |
| `finished` | ISO timestamp or `null` |

A phase is **stuck** when `state` is `EXECUTING` and `finished` is `null` for an extended period.

### Approval Detail Object (`approvalDetails[]`)

Contains information about who needs to approve and their current status. Check this to identify which approver is blocking the request.

### Request States

- `EXECUTING` — request is in progress (may be stuck)
- `PENDING` — waiting for action (approval, provisioning queue)
- `REQUEST_COMPLETED` — success
- `NOT_ALL_ITEMS_PROVISIONED` — partially failed
- `ERROR` — failed entirely

---

## Standard Cancel

```
POST /v2025/access-requests/cancel
```

**Request body:**
```json
{
  "accountActivityId": "<accountActivityItemId from the request>",
  "comment": "Reason for cancellation"
}
```

Field mapping:
- Body field `accountActivityId` ← request field `accountActivityItemId`
- Body field `comment` ← free text reason

**Precondition:** The request must have `cancelable: true`.

**Success response:** `202 Accepted`

**Common errors:**
- `400 Invalid request in current state` — the request has `cancelable: false`, use force-close instead
- `400 Illegal value for accountActivityId` — wrong ID format or value

---

## Force Close (Beta)

Use when the standard cancel fails because `cancelable: false`.

```
POST /beta/access-requests/close
```

**Request body:**
```json
{
  "accessRequestIds": ["<accessRequestId from the request>"],
  "message": "Reason for force-closing"
}
```

Field mapping:
- Body field `accessRequestIds` (array) ← request field `accessRequestId`
- Body field `message` ← free text reason

**Differences from standard cancel:**
| | Standard Cancel | Force Close |
|---|---|---|
| Endpoint | `/v2025/access-requests/cancel` | `/beta/access-requests/close` |
| ID field in body | `accountActivityId` (string) | `accessRequestIds` (array) |
| ID source field | `accountActivityItemId` | `accessRequestId` |
| Reason field | `comment` | `message` |
| API version | v2025 | beta |

**Success response:** `202 Accepted` with:
```json
{
  "id": "<job-uuid>",
  "errors": []
}
```

---

## Search Public Identities

```
GET /v2025/public-identities
```

Use to resolve an identity name to an ID when the user provides a name instead of an ID.

```bash
sail api get '/v2025/public-identities' -q 'filters=name eq "John Smith"'
```

---

## sail CLI Notes

- The `sail api` commands prefix output with a log line: `INFO Making GET request endpoint=...`
- The response status is appended as a suffix: `Status: 200 OK`
- Strip both before parsing JSON
- Use `-q 'key=value'` for GET query parameters
- Use `--body '{...}'` for POST request bodies
