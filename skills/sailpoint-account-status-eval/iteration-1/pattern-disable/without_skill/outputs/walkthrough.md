# Walkthrough: Disable All Accounts Matching X_* in Active Directory

## Objective

Disable every account whose `nativeIdentity` (or account name) matches the pattern `X_*` on an Active Directory source in SailPoint Identity Security Cloud, using the `sail` CLI and ISC APIs.

---

## Step 0: Verify the Active Environment

Before doing anything, confirm which tenant the CLI is pointed at.

```bash
sail environment show
```

**Expected output:** The name, base URL, and tenant details of the currently active environment. Verify this is the correct tenant (e.g., production vs. sandbox) before proceeding.

---

## Step 1: Identify the Active Directory Source ID

We need the source ID for the Active Directory source. Use the search or list capability to find it.

```bash
sail search query --query "name:\"Active Directory\"" --indices sources
```

Alternatively, use the API directly via `curl` or a scripted call:

```bash
curl -s -X GET \
  "${SAIL_BASE_URL}/v2025/sources?filters=name eq \"Active Directory\"" \
  -H "Authorization: Bearer $(sail token)" \
  -H "Content-Type: application/json" | jq '.[] | {id, name, type}'
```

**Expected output:** A JSON object (or list) containing the source's `id` (e.g., `2c91808a7a2b3c4d5e6f...`), `name` (`Active Directory`), and `type` (`Active Directory - Direct`). Note the `id` value for subsequent steps.

If there are multiple AD sources, identify the correct one by name or description.

---

## Step 2: Search for Accounts Matching the X_* Pattern

Use the ISC Search API (Elasticsearch-based) to find all accounts on that source whose `nativeIdentity` starts with `X_`.

```bash
curl -s -X POST \
  "${SAIL_BASE_URL}/v2025/search" \
  -H "Authorization: Bearer $(sail token)" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": ["accounts"],
    "query": {
      "query": "nativeIdentity:X_* AND sourceId:<SOURCE_ID>"
    },
    "sort": ["nativeIdentity"],
    "count": true
  }' | jq '[.[] | {id, nativeIdentity, name, disabled}]'
```

Replace `<SOURCE_ID>` with the actual source ID from Step 1.

**Expected output:** A JSON array of account objects. Each entry includes:
- `id` — the ISC account ID (needed for the disable call)
- `nativeIdentity` — the AD sAMAccountName or DN (should match `X_*`)
- `name` — display name of the account
- `disabled` — current status (`false` means the account is currently enabled)

**Important checks at this stage:**
1. Review the total count (returned in the `X-Total-Count` response header). If there are more than 250 results, the search is paginated and you must loop with `searchAfter` to collect all account IDs.
2. Visually inspect a sample of results to confirm the pattern match is correct and you are not catching unintended accounts.
3. Filter out any accounts that are already disabled (`disabled: true`) to avoid unnecessary API calls.

---

## Step 3: Handle Pagination (If Needed)

If the total count exceeds 250 (the default/max page size), paginate through results:

```bash
# First page (already done in Step 2). Capture the last sort value.
# Subsequent pages use searchAfter:

curl -s -X POST \
  "${SAIL_BASE_URL}/v2025/search" \
  -H "Authorization: Bearer $(sail token)" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": ["accounts"],
    "query": {
      "query": "nativeIdentity:X_* AND sourceId:<SOURCE_ID>"
    },
    "sort": ["nativeIdentity"],
    "searchAfter": ["<LAST_NATIVE_IDENTITY_FROM_PREVIOUS_PAGE>"]
  }' | jq '[.[] | {id, nativeIdentity, disabled}]'
```

Repeat until you get an empty result set. Collect all account IDs into a list.

---

## Step 4: Disable Each Account

ISC exposes an account enable/disable operation through the Accounts API. For each account, send a disable request.

**Single account disable:**

```bash
curl -s -X POST \
  "${SAIL_BASE_URL}/v2025/accounts/<ACCOUNT_ID>/disable" \
  -H "Authorization: Bearer $(sail token)" \
  -H "Content-Type: application/json" \
  -d '{
    "forceProvisioning": false
  }'
```

**Expected output:** A `202 Accepted` or `200 OK` response with a task result object containing a `taskId` or `taskResultId`. This confirms the disable request has been queued for provisioning to Active Directory.

**Scripted loop to disable all matching accounts:**

```bash
# Assume ACCOUNT_IDS is a file with one account ID per line,
# collected from Steps 2-3.

while IFS= read -r ACCOUNT_ID; do
  echo "Disabling account: ${ACCOUNT_ID}"
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "${SAIL_BASE_URL}/v2025/accounts/${ACCOUNT_ID}/disable" \
    -H "Authorization: Bearer $(sail token)" \
    -H "Content-Type: application/json" \
    -d '{"forceProvisioning": false}')

  if [ "$RESPONSE" -eq 202 ] || [ "$RESPONSE" -eq 200 ]; then
    echo "  -> Queued successfully (HTTP ${RESPONSE})"
  else
    echo "  -> FAILED (HTTP ${RESPONSE})"
  fi

  # Rate limiting: ISC APIs are rate-limited; pause between calls
  sleep 0.5
done < account_ids.txt
```

**Key considerations:**
- **Rate limiting:** ISC enforces API rate limits. Adding a small delay (0.5-1s) between requests avoids `429 Too Many Requests` errors.
- **`forceProvisioning`:** Setting this to `true` would force the disable even if the account is already marked as disabled in ISC. Leave it `false` for normal operation.
- **Batch size:** For large sets (hundreds of accounts), consider breaking into batches and monitoring provisioning completion between batches.

---

## Step 5: Verify the Results

After the disable requests have been processed, verify the accounts are now disabled.

**Option A: Re-run the search and check the `disabled` field:**

```bash
curl -s -X POST \
  "${SAIL_BASE_URL}/v2025/search" \
  -H "Authorization: Bearer $(sail token)" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": ["accounts"],
    "query": {
      "query": "nativeIdentity:X_* AND sourceId:<SOURCE_ID>"
    }
  }' | jq '[.[] | {nativeIdentity, disabled}]'
```

**Expected output:** All accounts should now show `"disabled": true`.

**Option B: Check a specific account:**

```bash
curl -s -X GET \
  "${SAIL_BASE_URL}/v2025/accounts/<ACCOUNT_ID>" \
  -H "Authorization: Bearer $(sail token)" | jq '{nativeIdentity, disabled}'
```

**Option C: Check provisioning activity / task status:**

If you captured `taskResultId` values from the disable responses, check their status:

```bash
curl -s -X GET \
  "${SAIL_BASE_URL}/v2025/task-status/<TASK_RESULT_ID>" \
  -H "Authorization: Bearer $(sail token)" | jq '{completionStatus, completed}'
```

**Expected output:** `completionStatus: "Success"` and `completed: true`.

---

## Important Notes and Risks

1. **This is a destructive operation.** Disabling accounts in AD locks users out. Always confirm the target environment and review the matched accounts before executing.
2. **Run in sandbox first.** If a sandbox/test tenant is available, execute this flow there before touching production.
3. **Governance:** Depending on the organization's policies, disabling accounts in bulk may require an approval workflow or change ticket. Check whether access request or certification processes should be used instead of direct API calls.
4. **Rollback:** To re-enable accounts, the same loop can be used with the `/enable` endpoint instead of `/disable`.
5. **Search index lag:** The ISC search index is eventually consistent. After disabling accounts, it may take a few minutes for the `disabled` field to update in search results. The direct GET on `/accounts/<id>` is more immediately accurate.
6. **Aggregation:** If a source aggregation runs after disabling, ISC will pick up the disabled status from AD and reflect it. No additional action is needed on the ISC side.
