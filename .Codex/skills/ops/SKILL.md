---
name: ops
description: Use to check operational risk before sharing or deployment: logs, observability, configuration, scheduler, external dependency, health, rollback, and secrets.
---

# Ops

## Rules

- Check whether failures can be traced.
- Check whether logs include correlation context without secrets.
- Check configuration differences across environments.
- Check scheduler or repeated job duplication risk.
- Check external dependency timeout and failure handling.
- Check health/readiness needs.
- Check rollback and migration risk.
- If risk remains, return to `dev` or `document`.
- For full-flow work, update `04-ops-check.md` and `harness.json`.

## Output

- Operational risks
- Mitigations
- Remaining risk
- Required documentation
