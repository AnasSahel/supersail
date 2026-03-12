# API Endpoints Reference

## List SoD Policies

```
GET /v2025/sod-policies
```

Query parameters:
- `limit` — max results (default 250)
- `filters` — SCIM filter (e.g., `state eq "ENFORCED"`)

Returns a JSON array of SoD policy objects. Key fields per object:

| Field | Description |
|-------|-------------|
| `id` | Policy ID |
| `name` | Policy name |
| `description` | What the policy is meant to prevent |
| `state` | `ENFORCED` or `NOT_ENFORCED` |
| `type` | `CONFLICTING_ACCESS_BASED` |
| `conflictingAccessCriteria.leftCriteria` | First set of conflicting access items |
| `conflictingAccessCriteria.rightCriteria` | Second set of conflicting access items |
| `created` | ISO timestamp |
| `modified` | ISO timestamp |

Each criteria side contains:
```json
{
  "name": "criteria-name",
  "criteriaList": [
    {
      "type": "ENTITLEMENT",
      "id": "entitlement-id",
      "name": "entitlement-name"
    }
  ]
}
```

---

## Get SoD Violations

```
GET /v2025/sod-violations
```

Query parameters:
- `limit` — max results (default 250)

Returns violation objects linking identities to the SoD policies they violate. Key fields:

| Field | Description |
|-------|-------------|
| `id` | Violation ID |
| `policy` | `{id, name}` — the SoD policy violated |
| `identity` | `{id, name}` — the identity in violation |
| `conflictingAccessItems` | Array of the specific access items causing the conflict |
| `created` | ISO timestamp |

---

## Get Identity Access

```
GET /v2025/identities/{id}/access
```

Query parameters:
- `limit` — max results (default 250)
- `type` — filter by access type: `ROLE`, `ENTITLEMENT`, `ACCESS_PROFILE`

Returns a JSON array of access items assigned to the identity:

| Field | Description |
|-------|-------------|
| `id` | Access item ID |
| `name` | Access item name |
| `type` | `ROLE`, `ENTITLEMENT`, `ACCESS_PROFILE` |
| `source` | `{id, name}` — the source the access belongs to |
| `entitlements` | Nested entitlements (for roles/access profiles) |
| `description` | Access item description |
| `privileged` | `true` or `false` — whether the access is marked as privileged |
| `standalone` | Whether the entitlement was directly assigned |

---

## Search Identities

```
POST /v2025/search
```

**Request body:**
```json
{
  "indices": ["identities"],
  "query": {
    "query": "<query string>"
  },
  "queryType": "SAILPOINT",
  "sort": ["name"],
  "searchAfter": []
}
```

Useful query strings for toxic access detection:

| Query | Purpose |
|-------|---------|
| `name:"John Doe"` | Find a specific identity |
| `access.id:{accessId}` | Identities with a specific access item |
| `access.id:{id1} AND access.id:{id2}` | Identities with both access items (toxic combo) |
| `access.name:*admin*` | Identities with admin-related access |
| `access.type:ROLE` | All identities with role assignments |
| `NOT attributes.cloudLifecycleState:active` | Inactive/terminated identities |
| `(access.name:*admin*) AND NOT attributes.cloudLifecycleState:active` | Orphaned privileged access |
| `@accounts.source.name:"Active Directory"` | Identities with accounts on a specific source |

Key response fields per identity:

| Field | Description |
|-------|-------------|
| `id` | Identity ID |
| `name` | Display name |
| `attributes.cloudLifecycleState` | `active`, `inactive`, `terminated`, etc. |
| `access[]` | Array of access items with `id`, `name`, `type`, `source` |
| `accounts[]` | Array of accounts with `source.name`, `disabled`, `privileged` |
| `entitlementCount` | Total number of entitlements |
| `roleCount` | Total number of roles |

---

## Search Account Activities

```
POST /v2025/search
```

**Request body for recent SoD-related activities:**
```json
{
  "indices": ["accountactivities"],
  "query": {
    "query": "action:SOD_VIOLATION_DETECTED"
  },
  "queryType": "SAILPOINT",
  "sort": ["modified"],
  "searchAfter": []
}
```

---

## sail CLI Notes

- The `sail api` commands prefix output with a log line: `INFO Making GET/POST request endpoint=...`
- The response status is appended as a suffix: `Status: 200 OK`
- Strip both before parsing JSON
- Use `-q 'key=value'` for query parameters on GET requests only
- Use `--body '{...}'` for POST request bodies
- The `-q` flag does NOT work on POST requests — put everything in the `--body` JSON
