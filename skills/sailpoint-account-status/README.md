# SailPoint Account Toggle

A Claude Code skill for enabling or disabling accounts in a SailPoint Identity Security Cloud source.

## What it does

1. **Environment selection** — Lists available SailPoint environments and lets you pick one
2. **Source identification** — Find the target source by name or browse available sources
3. **Account listing** — Shows enabled/disabled counts with optional pattern filtering
4. **Enable/Disable** — Single account, filtered batch, or bulk all — with progress reporting
5. **Verification** — Checks task status and reports success/failure with error details

## Install

```bash
claude install-skill https://github.com/AnasSahel/supersail/tree/main/skills/sailpoint-account-toggle
```

## Prerequisites

- [SailPoint CLI](https://github.com/sailpoint-oss/sailpoint-cli) (`sail`) installed and configured
- Admin permissions on the target ISC tenant

## Example triggers

- "Disable all accounts in Active Directory"
- "Enable the account X_samfak"
- "Disable all accounts matching X_*"
- "How many accounts are enabled in this source?"
- "Re-enable the accounts I disabled earlier"
