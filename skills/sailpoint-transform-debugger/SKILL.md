---
name: sailpoint-transform-debugger
description: Debug and fix SailPoint identity transforms that produce wrong output. Use this skill whenever the user mentions a transform not working, an identity attribute showing the wrong value, a calculated attribute being incorrect, attribute mapping issues, display name or email being wrong, identity profile calculations failing, concat/lookup/conditional/dateFormat transforms producing unexpected results, "null" appearing in attribute values, transforms returning empty or null, or any question about why an identity attribute has the wrong value in SailPoint Identity Security Cloud. Also trigger on phrases like "why is this attribute wrong", "transform is broken", "display name is wrong", "email format is incorrect", "attribute shows null", "identity attribute not calculating", "mapping is wrong", or "fix my transform".
---

# SailPoint Transform Debugger

Explain why a SailPoint identity transform produces the wrong output and suggest a corrected definition.

## Prerequisites

- The `sail` CLI must be installed and configured
- Admin permissions on the target ISC tenant (ability to read and update transforms)

## Workflow

### Step 1: Environment Selection

Before doing anything, show the user which environments are available and ask them to pick one:

```bash
sail environment list
sail environment show  # show current
```

Present the list and ask: "Which environment should I operate in?" Then switch:

```bash
sail environment use {name}
```

### Step 2: Identify the Transform

The user might provide a transform name, an identity attribute name, or just describe the problem ("display name is showing null"). Work from whatever they give you.

**List all transforms:**
```bash
sail api get '/v2025/transforms'
```

**Get a specific transform by ID:**
```bash
sail api get '/v2025/transforms/{id}'
```

**Alternative — use the sail transform subcommand:**
```bash
sail transform list
sail transform download
```

If the user gave an identity attribute name instead of a transform name, list all transforms and match by name (transforms are often named after the attribute they calculate, e.g., "Calculate Display Name" for `displayName`).

### Step 3: Analyze the Transform

Read the full transform JSON definition. Transforms have this structure:

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

Key fields:
- `type` — the transform type (determines behavior)
- `attributes` — configuration specific to the type
- Transforms nest — an input to one transform is the output of another

**Walk through the transform tree from leaf nodes to root.** For each node, determine what value it would produce and whether that value is correct.

#### Common Transform Types and What Goes Wrong

| Type | Common Issues |
|------|---------------|
| `accountAttribute` | Wrong `sourceName`, wrong `attributeName`, wrong or missing `accountPropertyFilter`, source not connected |
| `identityAttribute` | References an attribute that doesn't exist on the identity or is empty/null |
| `static` | Hardcoded value when dynamic was intended |
| `conditional` | Wrong expression syntax, wrong comparison operators (`eq` vs `==`), null handling |
| `lookup` | Missing key in lookup table, wrong or missing `default` value |
| `substring` | Wrong `begin`/`end` indices, off-by-one errors, input shorter than expected |
| `concat` | Wrong values array, null inputs producing the literal string `"null"`, missing separator |
| `dateFormat` | Wrong `inputFormat` or `outputFormat` patterns, timezone issues |
| `dateCompare` | Wrong `firstDate`/`secondDate` references, wrong `operator`, wrong `positiveCondition`/`negativeCondition` |
| `firstValid` | Order matters — first non-null wins, so check if a bad value appears before a good one |
| `split` | Wrong `delimiter`, wrong `index`, input doesn't contain the delimiter |
| `trim` | Applied to null (returns null, not empty string) |
| `lower` / `upper` | Applied to null |
| `replace` | Regex pattern doesn't match, replacement string wrong |
| `reference` | References another transform by name — check that the referenced transform exists and is correct |
| `rule` | Cloud rule errors, null pointer exceptions in the rule logic, wrong rule name |

### Step 4: Test with an Identity

If the user wants to understand why a specific identity has the wrong value, look up that identity and trace the transform with real data.

**Find the identity:**
```bash
sail api get '/v2025/identities' -q 'filters=name eq "John Smith"'
```

or by alias/email:
```bash
sail api get '/v2025/identities' -q 'filters=alias eq "jsmith"'
```

**Get identity details (attributes and accounts):**
```bash
sail api get '/v2025/identities/{identityId}'
```

**Get the identity's accounts to see source attribute values:**
```bash
sail api get '/v2025/accounts' -q 'filters=identityId eq "{identityId}"'
```

Now walk through the transform logic step by step using the actual attribute values from the identity and their accounts:

1. Start at the leaf nodes — resolve `accountAttribute` and `identityAttribute` references to their actual values
2. Apply each transform operation with those values
3. Compare the computed result to the actual attribute value on the identity
4. Identify where the divergence happens

Present the trace clearly:

```
Transform: Calculate Display Name (type: concat)
  Input 1: identityAttribute "firstname" -> "John"
  Input 2: static " "
  Input 3: identityAttribute "lastname" -> null    <-- PROBLEM: lastname is null
  Result: "John null"                               <-- "null" is coerced to string
  Expected: "John Smith"
```

### Step 5: Suggest Fix

Based on the analysis:

1. **Show the current transform definition** — the full JSON
2. **Explain what's wrong** — be specific about which node in the transform tree is producing the wrong value and why
3. **Propose a corrected transform JSON** — the complete updated definition, not just a diff
4. **Offer to apply the fix:**

```bash
sail transform upload --file transform.json
```

Or via the API:

```bash
sail api put '/v2025/transforms/{id}' --body '<updated JSON>'
```

Always ask for user confirmation before updating the transform.

#### Common Fix Patterns

- **"null" appearing in concatenated strings**: Wrap inputs in `firstValid` with a fallback to empty string:
  ```json
  {"type": "firstValid", "attributes": {"values": [
    {"type": "identityAttribute", "attributes": {"name": "lastname"}},
    {"type": "static", "attributes": {"value": ""}}
  ]}}
  ```

- **Wrong source attribute**: Check the actual source attribute name (case-sensitive) by examining an account from that source

- **Conditional not matching**: Verify the expression syntax — SailPoint uses `eq`, `ne`, `gt`, `lt`, `gte`, `lte` operators, and string comparisons are case-sensitive

- **Lookup missing a key**: Add the missing key, or ensure a `default` value is set for unmapped keys

- **dateFormat failing**: Ensure `inputFormat` matches the actual date string format from the source (common mistake: source sends `MM/dd/yyyy` but transform expects `yyyy-MM-dd`)

- **firstValid returning wrong value**: Reorder — put the preferred source first, fallback sources after

## API Quick Reference

See `references/api-endpoints.md` for detailed request/response formats.
