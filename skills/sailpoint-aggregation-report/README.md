# SailPoint Aggregation Report

A Claude Code skill that generates health reports on SailPoint ISC source aggregations.

## What it does

Queries the ISC Search API for `source_management` events and produces a breakdown of which sources are healthy, which are failing, and what needs attention.

## Install

```bash
claude install-skill https://github.com/AnasSahel/sailpoint-skills/tree/main/skills/sailpoint-aggregation-report
```

## Prerequisites

- [SailPoint CLI](https://github.com/sailpoint-oss/sailpoint-cli) (`sail`) installed and configured

## Example triggers

- "How are my aggregations doing?"
- "Show me source failures"
- "Aggregation report for the last 24 hours"
- "Which sources are failing?"
