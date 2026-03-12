---
name: sailpoint-toxic-access-detector
description: Detect toxic access combinations, segregation-of-duties (SoD) violations, and dangerous privilege accumulation in SailPoint Identity Security Cloud. Use this skill whenever the user mentions SoD violations, SoD policies, segregation of duties, toxic access, toxic combinations, dangerous access, risky access patterns, privilege escalation, privilege review, privileged access review, conflicting entitlements, conflicting roles, access risk analysis, compliance check, compliance review, access certification prep, who has too much access, blast radius, orphaned privileged accounts, approve and execute on same system, admin plus user on same source, overprivileged identities, access risk report, or any mention of finding, detecting, auditing, or flagging risky, dangerous, conflicting, or toxic access in SailPoint ISC.
---

# SailPoint Toxic Access Detector

Detect segregation-of-duties (SoD) violations, toxic access combinations, and dangerous privilege accumulation across identities in SailPoint Identity Security Cloud.

## Prerequisites

- The `sail` CLI must be installed and configured
- Admin permissions on the target ISC tenant (read access to identities, roles, entitlements, and SoD policies)

## Workflow

### Step 1: Environment Selection

Before doing anything, show the user which environments are available and ask them to pick one. Operating on the wrong tenant means analyzing the wrong data.

```bash
sail environment list
sail environment show  # show current
```

Present the list and ask: "Which environment should I operate in?" Then switch:

```bash
sail environment use {name}
```

### Step 2: Understand the Scope

Ask the user what they want to check. The scope determines which API calls to make:

- **A specific identity's access** — deep-dive on one person's access for toxic combinations
- **All identities with a certain role/entitlement combination** — targeted search for a known risky pair
- **Known SoD policies in the tenant** — review what's already defined and check for violations
- **A general scan for risky patterns** — broad sweep for common toxic combinations

If the user is vague, start with option 3 (SoD policies) to see what the organization has already defined, then offer to do a broader scan.

### Step 3: Check Existing SoD Policies

SailPoint ISC has built-in SoD policy support. Fetch all policies:

```bash
sail api get '/v2025/sod-policies' -q 'limit=250'
```

The CLI prefixes a log line (`INFO Making GET request...`) and suffixes a status line — strip both before parsing JSON.

Each SoD policy defines two sets of conflicting access items. For each policy, note:
- `name` and `description` — what the policy is meant to prevent
- `state` — `ENFORCED` or `NOT_ENFORCED` (disabled policies are a finding in themselves)
- `type` — `CONFLICTING_ACCESS_BASED` is the standard type
- `conflictingAccessCriteria.leftCriteria` and `rightCriteria` — the two sides of the conflict, each containing access items (roles, entitlements, or access profiles)

Then check for existing violations:

```bash
sail api get '/v2025/sod-violations' -q 'limit=250'
```

If the tenant has no SoD policies defined, note this as a gap and proceed to pattern-based detection in Step 5.

### Step 4: Analyze Identity Access

Depending on the scope from Step 2:

**For a specific identity:**

First find the identity:
```bash
sail api post '/v2025/search' --body '{"indices":["identities"],"query":{"query":"name:\"John Doe\""},"queryType":"SAILPOINT"}'
```

Then get their full access:
```bash
sail api get '/v2025/identities/{id}/access' -q 'limit=250'
```

This returns all roles, entitlements, and access profiles assigned to the identity. Build a complete picture of what the identity has access to.

**For identities with a specific role/entitlement combination:**

```bash
sail api post '/v2025/search' --body '{"indices":["identities"],"query":{"query":"access.id:{accessId1} AND access.id:{accessId2}"},"queryType":"SAILPOINT"}'
```

**For a broader scan — identities with privileged access:**

```bash
sail api post '/v2025/search' --body '{"indices":["identities"],"query":{"query":"access.type:ROLE"},"queryType":"SAILPOINT","sort":["name"],"searchAfter":[]}'
```

Or search for identities with specific entitlement names that suggest privilege:
```bash
sail api post '/v2025/search' --body '{"indices":["identities"],"query":{"query":"access.name:*admin* OR access.name:*Admin* OR access.name:*privileged* OR access.name:*superuser*"},"queryType":"SAILPOINT"}'
```

Cross-reference every identity's access list against the SoD policies found in Step 3.

### Step 5: Detect Risky Patterns

Beyond formal SoD policies, flag common toxic combinations. These are risk indicators, not definitive violations — the user's organization defines what's truly toxic.

**Pattern 1: Admin + regular user on same system (privilege escalation risk)**
- Identity has both an admin-level entitlement and a standard-user entitlement on the same source
- Example: "AD Admin" role plus "AD Standard User" on Active Directory
- Risk: The admin role may be used to elevate the standard account's privileges

**Pattern 2: Approve + execute on same process (fraud risk)**
- Identity can both submit/initiate and approve on the same system
- Example: "AP Invoice Creator" and "AP Invoice Approver" entitlements
- Risk: The identity can create and approve their own transactions

**Pattern 3: Read + write + delete on sensitive data (data destruction risk)**
- Identity has full CRUD access to a sensitive data store
- Example: "DB Read", "DB Write", "DB Delete" on a financial database source
- Risk: A single compromised account can exfiltrate and destroy data

**Pattern 4: Multiple privileged roles across systems (blast radius risk)**
- Identity holds admin-level roles on 3+ different sources
- Risk: If this identity is compromised, the attacker has wide lateral movement

**Pattern 5: Orphaned privileged access (lifecycle risk)**
- Identity has privileged entitlements but lifecycle state is not `active`
- Search for this:
```bash
sail api post '/v2025/search' --body '{"indices":["identities"],"query":{"query":"(access.name:*admin* OR access.name:*privileged*) AND NOT attributes.cloudLifecycleState:active"},"queryType":"SAILPOINT"}'
```
- Risk: Terminated or inactive users retaining privileged access is a critical finding

For each risky pattern detected, record the identity, the specific access items involved, the pattern matched, and a risk level (Critical / High / Medium / Low).

### Step 6: Generate Report

Present findings in a structured report:

```
# Toxic Access Report

## Environment
- Tenant: {tenant name}
- Date: {today}

## SoD Policy Violations
| Identity | Policy | Conflicting Items | Severity |
|----------|--------|--------------------|----------|
| ...      | ...    | ...                | ...      |

## Disabled SoD Policies (Gap)
| Policy Name | Description | State |
|-------------|-------------|-------|
| ...         | ...         | NOT_ENFORCED |

## Risky Access Patterns
| Identity | Pattern | Access Items | Risk Level | Recommendation |
|----------|---------|--------------|------------|----------------|
| ...      | ...     | ...          | ...        | ...            |

## Privileged Access Summary
| Identity | Privileged Roles/Entitlements | Source | Lifecycle State |
|----------|-------------------------------|--------|-----------------|
| ...      | ...                           | ...    | ...             |

## Summary
- Total SoD violations: X
- Disabled SoD policies: Y (review whether these should be enforced)
- Identities with risky patterns: Z
- Privileged accounts needing review: W
- Orphaned privileged accounts: V (CRITICAL — action required)
```

Offer to drill into any specific finding. Suggest next steps such as creating access certifications, enabling disabled SoD policies, or revoking orphaned privileged access.

## sail CLI Notes

- The `sail api` commands prefix output with a log line: `INFO Making GET/POST request endpoint=...`
- The response status is appended as a suffix: `Status: 200 OK`
- Strip both before parsing JSON
- Use `-q 'key=value'` for query parameters on GET requests only
- Use `--body '{...}'` for POST request bodies
- The `-q` flag does NOT work on POST requests — put everything in the `--body` JSON
- For search, always use `POST /v2025/search` with the body containing `indices`, `query`, and `queryType`
