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
- `filters=identityId eq "{id}"` — filter by identity
- `limit=250` — max per page (250 is the maximum)
- `offset=N` — pagination offset

Key fields per account:
| Field | Description |
|-------|-------------|
| `id` | Account UUID |
| `name` | Account name (e.g., sAMAccountName) |
| `nativeIdentity` | Full DN or native identifier in the source |
| `disabled` | Boolean — whether the account is disabled |
| `locked` | Boolean — whether the account is locked |
| `identityId` | Linked identity UUID — **null means orphan/uncorrelated** |
| `sourceId` | Source UUID the account belongs to |
| `created` | ISO timestamp of account creation |
| `modified` | ISO timestamp of last modification |

The `disabled` and `identityId` fields are **not filterable** via query params. You must paginate through all results and filter in memory.

---

## Search API

```
POST /v2025/search
```

Body format:
```json
{
  "indices": ["accountactivities"],
  "query": {
    "query": "source.id:{sourceId} AND uncorrelated:true"
  },
  "queryType": "SAILPOINT"
}
```

**Finding uncorrelated accounts:**
```json
{
  "indices": ["accountactivities"],
  "query": {
    "query": "source.id:{sourceId} AND uncorrelated:true"
  },
  "queryType": "SAILPOINT"
}
```

**Finding identities in inactive lifecycle states:**
```json
{
  "indices": ["identities"],
  "query": {
    "query": "lifecycleState:(inactive OR quit OR terminated OR disabled)"
  },
  "queryType": "SAILPOINT",
  "sort": ["name"]
}
```

The search API uses POST, so the `-q` flag does not work. Pass everything in `--body`.

For pagination in search, add `from` and `size` to the body:
```json
{
  "indices": ["identities"],
  "query": { "query": "lifecycleState:inactive" },
  "queryType": "SAILPOINT",
  "from": 0,
  "size": 250
}
```

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

## Delete Account

```
DELETE /v2025/accounts/{accountId}
```

Returns `202 Accepted` with a task result object. This is a destructive operation — always confirm with the user before executing.

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
- Use `-q 'key=value'` for query parameters on GET requests only
- Use `--body '{...}'` for POST request bodies
- The `-q` flag is only available on `GET` requests, not `POST`
- POST body JSON must be a single-line string passed to `--body`
