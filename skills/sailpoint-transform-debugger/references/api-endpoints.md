# API Endpoints Reference

## List Transforms

```
GET /v2025/transforms
```

Returns a JSON array of all transform objects in the tenant.

Key fields per transform:

| Field | Description |
|-------|-------------|
| `id` | Transform UUID |
| `name` | Transform name (e.g., "Calculate Display Name") |
| `type` | Transform type (`concat`, `lookup`, `conditional`, `accountAttribute`, etc.) |
| `attributes` | Configuration object — structure depends on `type` |
| `internal` | `true` for system transforms, `false` for custom |

---

## Get Transform by ID

```
GET /v2025/transforms/{id}
```

Returns a single transform object with the same fields as above.

---

## Update Transform

```
PUT /v2025/transforms/{id}
```

**Request body:** Full transform JSON (name, type, attributes). The `id` in the URL identifies the transform; the body replaces the definition.

```json
{
  "name": "Calculate Display Name",
  "type": "concat",
  "attributes": {
    "values": [
      {"type": "identityAttribute", "attributes": {"name": "firstname"}},
      {"type": "static", "attributes": {"value": " "}},
      {"type": "identityAttribute", "attributes": {"name": "lastname"}}
    ]
  }
}
```

**Success response:** `200 OK` with the updated transform object.

---

## List Identities

```
GET /v2025/identities
```

Query params (use `-q` flag with sail):
- `filters=name eq "John Smith"` — filter by display name
- `filters=alias eq "jsmith"` — filter by alias
- `limit=250` — max results per page
- `offset=N` — pagination offset

Key fields per identity:

| Field | Description |
|-------|-------------|
| `id` | Identity UUID |
| `name` | Display name |
| `alias` | Username / alias |
| `attributes` | Object containing all identity attributes (both standard and custom) |
| `accounts` | Array of linked account summaries |

---

## Get Identity by ID

```
GET /v2025/identities/{id}
```

Returns the full identity object including all attributes and account references.

---

## List Accounts

```
GET /v2025/accounts
```

Query params:
- `filters=identityId eq "{identityId}"` — all accounts for an identity
- `filters=sourceId eq "{sourceId}"` — all accounts in a source
- `limit=250` — max per page
- `offset=N` — pagination offset

Key fields per account:

| Field | Description |
|-------|-------------|
| `id` | Account UUID |
| `name` | Account name (e.g., sAMAccountName) |
| `nativeIdentity` | Full DN or native identifier |
| `sourceId` | Source UUID |
| `sourceName` | Source display name |
| `identityId` | Linked identity UUID |
| `attributes` | Object containing all account attributes from the source |
| `disabled` | Boolean |

---

## sail transform Subcommand

The `sail` CLI has a dedicated `transform` subcommand:

```bash
sail transform list          # list all transforms (name and ID)
sail transform download      # download all transforms as JSON files
sail transform upload --file transform.json  # upload/update a transform from file
```

`sail transform download` saves each transform as a separate JSON file in the current directory, named `{transform-name}.json`.

---

## sail CLI Notes

- API responses are prefixed with a log line: `INFO Making GET/POST/PUT request endpoint=...`
- Status line is appended: `Status: 200 OK`
- Strip both before parsing JSON
- Use `-q 'key=value'` for query parameters on GET requests (not inline in the URL)
- Use `--body '{...}'` for POST/PUT request bodies
- The `-q` flag is only available on `GET` requests, not `POST` or `PUT`
