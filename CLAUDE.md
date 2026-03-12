# SailPoint Skills

Repository for open-source SailPoint custom Skills, Agents, and related automation.

## What This Repo Contains

- **Skills** — Custom SailPoint SaaS connectors and skills
- **Agents** — SailPoint agent configurations and extensions
- **Workflows** — Identity lifecycle workflows and orchestration
- **Transforms** — Identity attribute transforms
- **Utilities** — Helper scripts and tooling for SailPoint development

## SailPoint Context

- SailPoint Identity Security Cloud (ISC) is the target platform
- API interactions go through the Identity Security Cloud APIs (versions: Beta, v3, v2024, v2025, v2026 — prefer v2025)
- API docs: https://developer.sailpoint.com/docs/api/{version} (e.g. https://developer.sailpoint.com/docs/api/v2025)
- Always verify which environment the CLI is targeting before running commands:
  - `sail environment show` — view the active environment
  - `sail environment list` — list all configured environments
  - `sail environment use {name}` — switch environment

## CLI

- The CLI is called `sail` (not `sp`) — installed via `brew install sailpoint-cli`
- Key commands: `sail connectors`, `sail transform`, `sail workflow`, `sail search`, `sail spconfig`, `sail va`, `sail cluster`
- Configure with `sail set` or via env vars: `SAIL_BASE_URL`, `SAIL_CLIENT_ID`, `SAIL_CLIENT_SECRET`

## Conventions

- Keep secrets out of source control — use environment variables or `.env` files (gitignored)
- Each skill/agent lives in its own directory with a local README
- Use TypeScript for custom connectors and skills unless there's a reason not to
- Follow SailPoint's naming conventions for transforms and rules

## Development

- Node.js / TypeScript for SaaS connectors
- `sail connectors` for connector lifecycle management
- Test locally with `sail connectors invoke` before deploying

## Useful References

- SailPoint Developer Docs: https://developer.sailpoint.com
- SailPoint CLI: https://github.com/sailpoint-oss/sailpoint-cli
- SailPoint API: https://developer.sailpoint.com/docs/api/{version}
