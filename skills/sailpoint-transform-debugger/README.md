# SailPoint Transform Debugger

A Claude Code skill for diagnosing and fixing SailPoint identity transforms that produce wrong output.

## What it does

1. **Environment selection** — Lists available SailPoint environments and lets you pick one
2. **Transform identification** — Finds the transform by name, identity attribute, or problem description
3. **Analysis** — Walks through the transform tree node by node, checking each operation
4. **Live testing** — Traces the transform with a real identity's data to pinpoint where it breaks
5. **Fix suggestion** — Proposes a corrected transform JSON and offers to apply it

## Install

```bash
claude install-skill https://github.com/AnasSahel/sailpoint-skills/tree/main/skills/sailpoint-transform-debugger
```

## Prerequisites

- [SailPoint CLI](https://github.com/sailpoint-oss/sailpoint-cli) (`sail`) installed and configured
- Admin permissions on the target ISC tenant

## Example triggers

- "Why is displayName showing null?"
- "My transform is producing the wrong email format"
- "The concat transform puts 'null' in the name"
- "Fix the Calculate Display Name transform"
- "Why does John Smith's department show as empty?"
- "The dateFormat transform isn't parsing dates correctly"
- "Identity attribute is wrong after aggregation"
- "Lookup transform missing a mapping"
