# SailPoint Orphan & Dormant Account Report

A Claude Code skill for detecting orphan (uncorrelated) accounts, dormant accounts, and cleanup candidates across SailPoint Identity Security Cloud sources.

## What it does

1. **Environment selection** — Lists available SailPoint environments and lets you pick one
2. **Scope selection** — Scan all sources, a specific source, or a selected list of sources
3. **Orphan detection** — Finds accounts with no linked identity (uncorrelated)
4. **Dormant detection** — Finds correlated accounts on inactive identities or accounts unchanged for 90+ days
5. **Structured report** — Presents orphan and dormant accounts with cleanup recommendations and priority rankings per source

## Install

```bash
claude install-skill https://github.com/AnasSahel/sailpoint-skills/tree/main/skills/sailpoint-orphan-and-dormant-account-report
```

## Prerequisites

- [SailPoint CLI](https://github.com/sailpoint-oss/sailpoint-cli) (`sail`) installed and configured
- Admin permissions on the target ISC tenant

## Example triggers

- "Find orphan accounts in Active Directory"
- "Show me uncorrelated accounts across all sources"
- "Run a stale account report"
- "Which accounts have no identity linked?"
- "Find dormant accounts that should be deprovisioned"
- "Account hygiene audit"
- "Clean up old accounts in my tenant"
- "Show me accounts on inactive identities"
