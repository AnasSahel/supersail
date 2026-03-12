# SailPoint Access Request Investigator

A Claude Code skill that investigates blocked, stuck, or failing access requests in SailPoint Identity Security Cloud and explains exactly where the request is blocked.

## What it does

1. **Environment selection** — Lists available SailPoint environments and lets you pick which one to operate on
2. **Find the request** — Locates the problematic request by ID, identity name, or by listing all pending/stuck requests
3. **Trace the lifecycle** — Walks through the request phases (approval, provisioning) to pinpoint the blockage
4. **Diagnose** — Explains in plain language where and why the request is blocked
5. **Resolve** — Offers cancellation or force-close options with user confirmation

## Install

```bash
claude install-skill https://github.com/AnasSahel/oss-sailpoint-skills/tree/main/skills/sailpoint-access-request-investigator
```

## Prerequisites

- [SailPoint CLI](https://github.com/sailpoint-oss/sailpoint-cli) (`sail`) installed and configured
- Admin permissions on the target ISC tenant

## Example triggers

- "Why is my access request stuck?"
- "Where is my request blocked?"
- "Show me pending access requests"
- "Who needs to approve my request?"
- "Provisioning failed on my access request"
- "What happened to my access request?"
- "My request has been pending for days"
- "Access request error — can you investigate?"
