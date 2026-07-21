---
name: test
description: Use to verify changes through existing tests, builds, API checks, browser checks, or manual validation plans.
---

# Test

## Rules

- Run existing tests first.
- Run build/type/lint checks when available.
- Cover every acceptance criterion from the plan: each maps to a test/check that passed,
  or an explicit waiver with a reason. Do not test only the easy criteria.
- Verify success and failure paths.
- Record commands, results, failures, and unverified items.
- If validation fails, return to `dev`.
- If a test cannot run, record why and provide a substitute check.
- For full-flow work, update `03-test-result.md` and `harness.json`.

## Output

- Commands run
- Passed
- Failed
- Unverified
- Reproduction steps
- Return-to-dev needed: yes/no
