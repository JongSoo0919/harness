# Harness Instructions

Use the bundled skills for harness-driven work.

Default flow:

```text
plan -> dev -> test -> ops -> document -> share
```

Rules:

- Read only relevant files.
- Keep changes minimal.
- Do not commit secrets.
- Do not perform destructive work without explicit human approval.
- Use `scripts/harness/run-gates.sh` before sharing.
- If an error came from a model assumption, record it and update the relevant rule.
- Wiki promotion is manual only. Humans approve final wiki documents.
