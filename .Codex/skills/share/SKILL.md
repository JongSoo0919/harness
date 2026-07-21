---
name: share
description: Use to prepare commit, push, PR, release note, or team summary after verification. Requires human approval before push or PR.
---

# Share

## Rules

- Check git status and diff.
- Run harness gates before commit/PR.
- Never commit secrets.
- Do not push or create PR without human approval.
- Summarize what changed, why, tests, risks, and docs.
- If outputs are missing, return to the relevant stage.

## PR Summary Shape

- Goal
- Changes
- Verification
- Operational impact
- Docs
- Risks
- Human approval
