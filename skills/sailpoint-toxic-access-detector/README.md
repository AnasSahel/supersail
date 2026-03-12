# SailPoint Toxic Access Detector

A Claude Code skill for detecting segregation-of-duties (SoD) violations, toxic access combinations, and dangerous privilege accumulation in SailPoint Identity Security Cloud.

## What it does

1. **Environment selection** — Lists available SailPoint environments and lets you pick which one to operate on
2. **Scope definition** — Asks whether to check a specific identity, a role/entitlement combination, existing SoD policies, or run a broad scan
3. **SoD policy review** — Fetches all SoD policies, checks for violations, and flags disabled policies as gaps
4. **Access analysis** — Pulls identity access data and cross-references against SoD policies
5. **Pattern detection** — Flags common toxic combinations beyond formal SoD policies (admin+user, approve+execute, orphaned privileged access, blast radius)
6. **Report generation** — Produces a structured report with violations, risky patterns, privileged access summary, and actionable recommendations

## Install

```bash
claude install-skill https://github.com/AnasSahel/sailpoint-skills/tree/main/skills/sailpoint-toxic-access-detector
```

## Prerequisites

- [SailPoint CLI](https://github.com/sailpoint-oss/sailpoint-cli) (`sail`) installed and configured
- Admin permissions on the target ISC tenant

## Example triggers

- "Check for SoD violations"
- "Who has toxic access combinations?"
- "Review privileged access across the tenant"
- "Does this identity have conflicting entitlements?"
- "Find orphaned admin accounts"
- "Run a compliance check on risky access patterns"
- "What SoD policies do we have and are any being violated?"
- "Check for approve and execute conflicts"
