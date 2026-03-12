# API Endpoints Reference

## Search Account Activities (Failed Provisioning)

```
POST /v2025/search
```

**Request body:**
```json
{
  "indices": ["accountactivities"],
  "query": {
    "query": "completionStatus:ERROR"
  },
  "queryType": "SAILPOINT",
  "sort": ["modified"],
  "searchAfter": []
}
```

Useful query variations:
- `completionStatus:ERROR AND target.name:"John Doe"` — filter by target identity
- `completionStatus:ERROR AND items.application:"Active Directory"` — filter by source name
- `completionStatus:ERROR AND modified:[now-7d TO now]` — last 7 days only

Returns array of account activity objects. Key fields:

| Field | Description |
|-------|-------------|
| `id` | Account activity UUID |
| `completionStatus` | `SUCCESS`, `ERROR`, `INCOMPLETE`, `null` (in progress) |
| `requester.name` | Who requested the action |
| `target.name` | Identity the action targets |
| `items[]` | Array of provisioning operation items |
| `items[].name` | Operation name (e.g., "Create Account", "Modify Account") |
| `items[].application` | Source/application name |
| `items[].status` | `FINISHED` (success) or `FAILED` |
| `items[].result` | Error message text when failed |
| `items[].nativeIdentity` | Account native identity in target system |
| `items[].operation` | `Create`, `Modify`, `Delete`, `Enable`, `Disable` |
| `created` | ISO timestamp |
| `modified` | ISO timestamp |

---

## Access Request Status

```
GET /v2025/access-request-status
```

Query params (use `-q` flag with sail):
- `filters=accessRequestId eq "{id}"` — filter by request ID

Key fields:

| Field | Description |
|-------|-------------|
| `name` | Name of the requested access |
| `type` | `ACCESS_PROFILE`, `ROLE`, `ENTITLEMENT` |
| `state` | `EXECUTING`, `PENDING`, `REQUEST_COMPLETED`, `NOT_ALL_ITEMS_PROVISIONED`, `ERROR` |
| `accessRequestId` | Unique request ID |
| `accountActivityItemId` | Activity ID — use to look up account activity |
| `errorMessages` | Array of error arrays, or `null` |
| `accessRequestPhases` | Array of phase objects |
| `requestedFor` | `{type, id, name}` |
| `requestedAccounts` | Array of `{sourceName, accountId, name}` |

---

## Task Status

```
GET /v2025/task-status/{taskId}
```

Key fields:

| Field | Description |
|-------|-------------|
| `completionStatus` | `SUCCESS`, `ERROR`, or `null` (in progress) |
| `target.name` | Identity affected |
| `completed` | ISO timestamp or `null` |
| `messages` | Array of error objects |
| `messages[].localizedText.message` | Human-readable error text |
| `messages[].type` | `Error`, `Warning`, `Info` |

---

## List Sources

```
GET /v2025/sources
```

Query params:
- `filters=name eq "Source Name"` — filter by name
- `limit=100` — max results per page

Key fields: `id`, `name`, `type`, `connector`, `healthy`, `cluster.id`.

---

## sail CLI Notes

- API responses are prefixed with a log line: `INFO Making GET/POST request endpoint=...`
- Status line is appended: `Status: 200 OK`
- Strip both before parsing JSON
- Use `-q 'key=value'` for query parameters — **GET requests only**
- Use `--body '{...}'` for POST request bodies
- The `-q` flag does NOT work on POST requests — include filters/params in the `--body` JSON
- For the search endpoint, everything goes in the body: indices, query, sort, pagination
