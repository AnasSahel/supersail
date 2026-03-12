# SailPoint Stuck Requests

A Claude Code skill for diagnosing and resolving stuck, waiting, or hung access requests in SailPoint Identity Security Cloud.

## What it does

1. **Environment selection** — Lists available SailPoint environments and lets you pick which one to operate on
2. **Discovery** — Fetches all access request statuses and filters for stuck ones (EXECUTING/PENDING)
3. **Diagnosis** — Examines error messages, phases, and account activity to identify the root cause
4. **Resolution** — Cancels or force-closes the stuck request via the appropriate API endpoint

## Install

```bash
claude install-skill https://github.com/AnasSahel/oss-sailpoint-skills/tree/main/skills/sailpoint-stuck-requests
```

## Prerequisites

- [SailPoint CLI](https://github.com/sailpoint-oss/sailpoint-cli) (`sail`) installed and configured
- Admin permissions on the target ISC tenant

## Example triggers

- "I have a stuck access request"
- "My request is pending for days"
- "Access request won't go through"
- "Force close a hung request"
