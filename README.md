# OSS SailPoint Skills

A collection of open-source SailPoint Skills, Agents, and automation built on top of the [SailPoint Identity Security Cloud (ISC)](https://www.sailpoint.com/products/identity-security-cloud) platform.

## Purpose

This repository centralizes SailPoint customizations — connectors, transforms, workflows, rules, and agents — making them version-controlled, reusable, and easy to deploy across tenants.

## What's Inside

| Directory | Description |
|-----------|-------------|
| `skills/` | Custom SaaS connectors and skills |
| `agents/` | Agent configurations and extensions |
| `workflows/` | Identity lifecycle workflows |
| `transforms/` | Identity attribute transforms |

## Prerequisites

- [SailPoint CLI (`sail`)](https://developer.sailpoint.com/docs/tools/cli) — the official CLI for interacting with ISC
- Access to a SailPoint ISC tenant
- Node.js (for TypeScript-based connectors)

### Install the SailPoint CLI

**macOS:**

```bash
brew tap sailpoint-oss/tap && brew install sailpoint-cli
```

**Windows:** Download the MSI installer from the [releases page](https://github.com/sailpoint-oss/sailpoint-cli/releases).

**Linux:** Install via `.deb` or `.rpm` from the [releases page](https://github.com/sailpoint-oss/sailpoint-cli/releases).

### Configure the CLI

```bash
sail set
```

You'll need your tenant URL and either OAuth credentials or a Personal Access Token (PAT).

For CI/CD, use environment variables:

```bash
export SAIL_BASE_URL=https://<tenant>.api.identitynow.com
export SAIL_CLIENT_ID=<client-id>
export SAIL_CLIENT_SECRET=<client-secret>
```

## Key `sail` Commands

| Command | What it does |
|---------|-------------|
| `sail connectors` | Create and manage SaaS connectors |
| `sail transform` | Create, manage, and test transforms |
| `sail workflow` | Build and manage workflows |
| `sail search` | Query ISC search |
| `sail spconfig` | Import/export tenant configuration |
| `sail va` | Manage Virtual Appliances |
| `sail cluster` | Manage VA clusters |

## Getting Started

1. Install and configure the `sail` CLI (see above)
2. Clone this repo
3. Navigate to the skill/agent/workflow you want to work on
4. Follow the local README in that directory

## Links

- [SailPoint Developer Docs](https://developer.sailpoint.com)
- [SailPoint CLI](https://github.com/sailpoint-oss/sailpoint-cli)
- [SaaS Connectivity SDK](https://github.com/sailpoint-oss/connector-sdk-js)
