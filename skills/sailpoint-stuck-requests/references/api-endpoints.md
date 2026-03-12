# API Endpoints Reference

## List Access Request Statuses

```
GET /v2025/access-request-status
```

Returns a JSON array of access request status objects. Key fields per object:

| Field | Description |
|-------|-------------|
| `name` | Name of the requested access (e.g., "Badge") |
| `type` | `ACCESS_PROFILE`, `ROLE`, `ENTITLEMENT` |
| `id` | Access item ID (not the request ID) |
| `state` | `EXECUTING`, `PENDING`, `REQUEST_COMPLETED`, `NOT_ALL_ITEMS_PROVISIONED`, `ERROR` |
| `cancelable` | `true` or `false` — determines which cancel path to use |
| `accessRequestId` | The unique request ID — used for force-close |
| `accountActivityItemId` | Activity ID — used for standard cancel |
| `errorMessages` | Array of error arrays, or `null` |
| `accessRequestPhases` | Array of phase objects with `name`, `state`, `started`, `finished` |
| `requester` | `{type, id, name}` |
| `requestedFor` | `{type, id, name}` |
| `requestedAccounts` | Array of `{sourceName, accountId, name}` |
| `created` | ISO timestamp |
| `modified` | ISO timestamp |

### Phase States
- `COMPLETED` — phase finished
- `EXECUTING` — phase is in progress (stuck if `finished` is `null` for a long time)

### Request States
- `EXECUTING` — request is in progress
- `PENDING` — waiting for action
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

**Success response:** `202 Accepted`

**Common errors:**
- `400 Invalid request in current state` — the request has `cancelable: false`
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

Note the differences from standard cancel:
- Uses `accessRequestIds` (array) not `accountActivityId` (string)
- Uses `message` not `comment`
- Uses the `accessRequestId` field, not `accountActivityItemId`
- This is a **beta** endpoint

**Success response:** `202 Accepted` with:
```json
{
  "id": "<job-uuid>",
  "errors": []
}
```

---

## sail CLI Notes

- The `sail api` commands prefix output with a log line: `INFO Making GET request endpoint=...`
- The response status is appended as a suffix: `Status: 200 OK`
- Strip both before parsing JSON
- Use `--body` flag for POST request bodies (not `--body-json`)
