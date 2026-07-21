---
name: flow
description: Use for full harness workflow across planning, development, testing, ops review, documentation, and sharing. If a task spans multiple stages, use this skill first.
---

# Flow

Default order:

```text
plan -> dev -> test -> ops -> document -> share
```

## Rules

- Follow `references/stage-routing.md`.
- Use `references/prompt-style.md` for concise output.
- Do not enter `dev` until the plan is approved.
- If `test` fails, return to `dev`.
- If `ops` finds risk, return to `dev` or `document`.
- Before PR, push, or external sharing, get human approval.
- Do not automate destructive work.
- Record commands, decisions, and failures under `.harness/runs/...`.
- If an error came from a model assumption, record the assumption and update the relevant rule.
- Record residual risk in `harness.json` `acceptedRisks[]` (each with a reason and approvedBy)
  rather than `openRisks` (which blocks). Do not hide risk to pass a gate; accept it on record.

## Triage (do this first)

Do not assume the full flow. Classify the request as S / M / L first, announce the
result and reason in one line, then route.

- **S (small) -> quick fix.** Skip the full flow: make the change directly and run a
  smoke check. Conditions: few files, small change, and NO change to permissions,
  disclosure scope, data/schema, external integrations, operational exposure, or new
  public APIs.
- **L (large) -> full flow** (`plan -> dev -> test -> ops -> document -> share`).
  Conditions: new feature, multi-area change, or any change to data/schema,
  permissions, external integrations, or operational exposure. Or the user asked to
  start from planning / run the whole flow.
- **M (medium) -> lite flow.** Between S and L: limited to one or two areas with none
  of the no-guess fields touched. lite = `plan` (short: `input.yaml` + brief
  `01-plan.md`) -> `dev` -> `test` (one smoke pass) -> `share`. Add `ops`/`document`
  only when operational impact or a documentation trigger exists.

- If the boundary is unclear, round UP to the heavier tier.
- If any no-guess field is involved (permissions, disclosure scope, data changes,
  external-access tests, operational exposure, destructive actions), treat the task as
  at least M and keep the plan-stage questions.
- Only ask the user when the S/M boundary itself is unclear; otherwise announce the
  tier and proceed.

## Visibility and effort budget

- **Declare auto vs decision points up front:** on entry, state how far you will
  proceed automatically and where a user decision is required.
- **Batch decisions:** ask all required decisions (no-guess fields, etc.) together
  rather than scattering them. Re-ask only the answers that were ambiguous.
- **Progress line:** on entering each stage, print one line: `[current/total] stage - what it does`.
- **Effort budget (avoid over-provisioning):**
  - S/M: cap at 1 app boot and 1 review pass. Re-boot or extra review only with a stated reason.
  - L: default 1 boot; add more only when verification genuinely needs it.
  - Reviews scale with change size. Do not fan out many review agents for a small change.
- Do not narrate trial-and-error. Surface only what the user must act on (decisions,
  blockers, approvals), then summarize at the end.

## References

- Stage routing: `references/stage-routing.md`
- Prompt style: `references/prompt-style.md`
