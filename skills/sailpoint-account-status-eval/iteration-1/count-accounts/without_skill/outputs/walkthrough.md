# Walkthrough: Counting Enabled and Disabled Accounts in Active Directory

## Goal

Determine how many accounts are enabled vs. disabled in the Active Directory source using the `sail` CLI and SailPoint Identity Security Cloud APIs.

---

## Step 1: Verify the Active Environment

Before doing anything, confirm which ISC tenant the CLI is pointed at.

```bash
sail environment show
```

**Expected output:** The currently active environment name, base URL, and authentication details (client ID, with secret masked). This ensures we are querying the correct tenant.

---

## Step 2: Identify the Active Directory Source ID

We need the internal source ID for the Active Directory source. Use the search or API to list sources and find it.

```bash
sail search query --query "name:\"Active Directory\"" --indices sources
```

Alternatively, if the source name is not exact or there are multiple AD sources, list all sources and filter:

```bash
curl -s -X GET \
  "${SAIL_BASE_URL}/v2025/sources?filters=name co \"Active Directory\"" \
  -H "Authorization: Bearer $(sail token)" \
  -H "Content-Type: application/json" | jq '.[].id, .[].name'
```

**Expected output:** One or more source objects. We need the `id` field, which will be something like `2c91808a7e123abc456def1234567890`. We also confirm the `name` matches (e.g., "Active Directory").

Let's assume the source ID is `2c91808a7e123abc456def1234567890` for the remaining steps.

---

## Step 3: Understand How Account Status Works in SailPoint

In SailPoint ISC, account objects have attributes that reflect their status. For Active Directory accounts, the key indicators are:

- **`disabled`** — A boolean attribute on the account object (`true` = disabled, `false` = enabled). This is derived from the AD `userAccountControl` attribute during aggregation.
- **`IIQDisabled`** — Another commonly used attribute indicating the account's disabled state.

The search index `accounts` exposes these attributes and supports filtering on them.

---

## Step 4: Count Enabled Accounts

Use the SailPoint Search API to query for accounts on the AD source that are NOT disabled.

```bash
sail search query \
  --query "source.id:\"2c91808a7e123abc456def1234567890\" AND disabled:false" \
  --indices accounts \
  --outputTypes json | jq 'length'
```

Or via direct API call (which gives us the `X-Total-Count` header for large result sets without fetching all records):

```bash
curl -s -o /dev/null -w "%{http_code}" -D - -X POST \
  "${SAIL_BASE_URL}/v2025/search/count" \
  -H "Authorization: Bearer $(sail token)" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": ["accounts"],
    "query": {
      "query": "source.id:\"2c91808a7e123abc456def1234567890\" AND disabled:false"
    }
  }'
```

A simpler approach using the search endpoint with `limit=0` to just get the count:

```bash
curl -s -X POST \
  "${SAIL_BASE_URL}/v2025/search" \
  -H "Authorization: Bearer $(sail token)" \
  -H "Content-Type: application/json" \
  -H "X-Total-Count: true" \
  -d '{
    "indices": ["accounts"],
    "query": {
      "query": "source.id:\"2c91808a7e123abc456def1234567890\" AND disabled:false"
    },
    "queryResultFilter": {},
    "searchAfter": [],
    "sort": ["id"]
  }' -D - -o /dev/null 2>&1 | grep -i x-total-count
```

**Expected output:** A header like `X-Total-Count: 1247`, indicating 1,247 enabled accounts.

---

## Step 5: Count Disabled Accounts

Repeat the same query but with `disabled:true`.

```bash
sail search query \
  --query "source.id:\"2c91808a7e123abc456def1234567890\" AND disabled:true" \
  --indices accounts \
  --outputTypes json | jq 'length'
```

Or via direct API:

```bash
curl -s -X POST \
  "${SAIL_BASE_URL}/v2025/search" \
  -H "Authorization: Bearer $(sail token)" \
  -H "Content-Type: application/json" \
  -H "X-Total-Count: true" \
  -d '{
    "indices": ["accounts"],
    "query": {
      "query": "source.id:\"2c91808a7e123abc456def1234567890\" AND disabled:true"
    },
    "sort": ["id"]
  }' -D - -o /dev/null 2>&1 | grep -i x-total-count
```

**Expected output:** A header like `X-Total-Count: 312`, indicating 312 disabled accounts.

---

## Step 6: Present the Results

Combine the two counts into a summary. If scripting this, something like:

```bash
SOURCE_ID="2c91808a7e123abc456def1234567890"
TOKEN=$(sail token)

ENABLED=$(curl -s -X POST "${SAIL_BASE_URL}/v2025/search" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Total-Count: true" \
  -d "{
    \"indices\": [\"accounts\"],
    \"query\": { \"query\": \"source.id:\\\"${SOURCE_ID}\\\" AND disabled:false\" },
    \"sort\": [\"id\"]
  }" -D - -o /dev/null 2>&1 | grep -i x-total-count | awk '{print $2}' | tr -d '\r')

DISABLED=$(curl -s -X POST "${SAIL_BASE_URL}/v2025/search" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Total-Count: true" \
  -d "{
    \"indices\": [\"accounts\"],
    \"query\": { \"query\": \"source.id:\\\"${SOURCE_ID}\\\" AND disabled:false\" },
    \"sort\": [\"id\"]
  }" -D - -o /dev/null 2>&1 | grep -i x-total-count | awk '{print $2}' | tr -d '\r')

echo "Active Directory Account Status Summary"
echo "========================================="
echo "Enabled accounts:  ${ENABLED}"
echo "Disabled accounts: ${DISABLED}"
echo "Total accounts:    $((ENABLED + DISABLED))"
```

**Expected output:**

```
Active Directory Account Status Summary
=========================================
Enabled accounts:  1247
Disabled accounts: 312
Total accounts:    1559
```

---

## Important Caveats

1. **Search index lag** -- The search index is eventually consistent. If a recent aggregation just completed, the counts may not reflect the very latest changes for a few minutes.

2. **Pagination limits** -- The `sail search query` command and the `/search` API return a maximum of 10,000 results per query. If the source has more than 10,000 accounts, the `jq 'length'` approach will cap at 10,000. Using the `X-Total-Count` header approach avoids this limitation since it returns the true total regardless of pagination.

3. **Source name ambiguity** -- There may be multiple sources with "Active Directory" in the name (e.g., "Active Directory - US", "Active Directory - EU"). Always verify you have the correct source ID in Step 2.

4. **Correlated vs. uncorrelated accounts** -- The search returns all accounts on the source, including uncorrelated ones. If you only want correlated (identity-linked) accounts, add `uncorrelated:false` to the query.

5. **Alternative: List Accounts API** -- You could also use `GET /v2025/accounts?filters=sourceId eq "..." and disabled eq false&count=true` with the List Accounts endpoint instead of Search. This also supports the `X-Total-Count` header when `count=true` is passed. However, the Search API is generally faster for count-only queries on large datasets.
