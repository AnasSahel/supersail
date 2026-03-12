# SailPoint Provisioning Failure Triage

A Claude Code skill for diagnosing why provisioning failed in SailPoint Identity Security Cloud — by source, operation, and root cause.

## What it does

1. **Environment selection** — Lists available SailPoint environments and lets you pick one
2. **Failure discovery** — Searches for failed provisioning via account activities, access request status, or task status
3. **Diagnosis** — Categorizes errors into connector errors, rule failures, target system errors, configuration errors, and workflow errors
4. **Report** — Presents findings grouped by source with the operation, error message, root cause, and suggested fix

## Install

```bash
claude install-skill https://github.com/AnasSahel/sailpoint-skills/tree/main/skills/sailpoint-provisioning-failure-triage
```

## Prerequisites

- [SailPoint CLI](https://github.com/sailpoint-oss/sailpoint-cli) (`sail`) installed and configured
- Admin permissions on the target ISC tenant

## Example triggers

- "Why did provisioning fail?"
- "Show me recent provisioning failures"
- "Account creation failed on Active Directory"
- "What went wrong with this access request?"
- "Provisioning error on ServiceNow"
- "BeforeProvisioning rule is throwing exceptions"
- "Password policy violation during disable"
- "Connector timeout on my source"
