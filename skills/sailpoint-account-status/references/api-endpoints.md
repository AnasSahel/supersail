# API Endpoints Reference

## List Sources

```
GET /v2025/sources
```

Query params (use `-q` flag with sail):
- `filters=name eq "Source Name"` — filter by name
- `limit=100` — max results per page

Returns array of source objects. Key fields: `id`, `name`, `type`, `connector`, `healthy`.

---

## List Accounts

```
GET /v2025/accounts
```

Query params:
- `filters=sourceId eq "{id}"` — filter by source
- `limit=250` — max per page (250 is the maximum)
- `offset=N` — pagination offset

The `disabled` field is **not filterable** via query params. You must paginate through all results and filter in memory.

Key fields per account:
- `id` — account UUID (used for disable/enable calls)
- `name` — account name (e.g., sAMAccountName)
- `nativeIdentity` — full DN or native identifier
- `disabled` — boolean
- `locked` — boolean
- `identityId` — linked identity UUID

---

## Disable Account

```
POST /v2025/accounts/{accountId}/disable
Body: {}
```

Returns `202 Accepted`:
```json
{"id": "task-uuid"}
```

The operation is async. The returned `id` is a task ID for status checking.

---

## Enable Account

```
POST /v2025/accounts/{accountId}/enable
Body: {}
```

Same response format as disable — `202 Accepted` with a task ID.

---

## Check Task Status

```
GET /v2025/task-status/{taskId}
```

Key fields:
| Field | Description |
|-------|-------------|
| `completionStatus` | `SUCCESS`, `ERROR`, or `null` (in progress) |
| `target.name` | Identity email/name affected |
| `completed` | ISO timestamp or `null` |
| `messages` | Array of error objects (if failed) |
| `messages[].localizedText.message` | Human-readable error text |

---

## sail CLI Notes

- API responses are prefixed with a log line: `INFO Making GET/POST request endpoint=...`
- Status line is appended: `Status: 200 OK`
- Strip both before parsing JSON
- Use `-q 'key=value'` for query parameters (not inline in the URL)
- Use `--body '{...}'` for POST request bodies
- The `-q` flag is only available on `GET` requests, not `POST`
