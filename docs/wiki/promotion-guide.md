# Wiki Promotion Guide

Wiki promotion is manual only.

The harness extracts drafts and validates promoted documents. It does not move, approve, or publish drafts automatically.

## Promotion Targets

- `docs/wiki/operation/`: operational policy, deployment, observability, external dependency, incident response
- `docs/wiki/development/`: development rules, architecture, API, data, permissions, exceptions, tests
- `docs/wiki/onboarding/`: workflow, terms, decision background, starter guidance
- `docs/wiki/lessons/`: failure lessons and prevention rules

## Promotion Conditions

- A human reviewed the document.
- A human approved promotion.
- The source work output path is present.
- The purpose and scope are clear.
- No secret values exist.
- Draft markers are removed.
- Reviewer, review date, approval, and category metadata exist.

## Required Metadata

```yaml
---
source: docs/work/YYYY-MM-DD-task
reviewer: reviewer-name
reviewedAt: YYYY-MM-DD
approval: approved
category: operation|development|onboarding|lessons
---
```

## Check

```bash
scripts/harness/check-wiki-promotion.sh --file docs/wiki/development/example.md
```

The script validates only. It never approves.
