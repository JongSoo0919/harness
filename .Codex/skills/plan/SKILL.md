---
name: plan
description: Use before implementation to clarify a product idea, new feature, maintenance task, bug fix, architecture change, or operational improvement. Ask until the goal is clear.
---

# Plan

## Purpose

Turn a vague request into an approved, buildable plan.

This works for both:

- new product or feature planning
- maintenance of an existing codebase

## Rules

- Keep asking until the model can explain the goal clearly.
- Clarify users, problem, scope, non-goals, constraints, risks, data, permissions, operations, and acceptance criteria.
- Write acceptance criteria as a testable checklist: each criterion must be something a
  test or a concrete check can prove. Vague criteria ("works well") are not accepted.
- For each acceptance criterion, note how it will be verified (which test or check), or
  explicitly waive it with a reason. Do not leave criteria unmapped.
- If this is a new product idea, define target users, core workflow, MVP, success criteria, and alternatives.
- If this is maintenance, inspect only relevant docs and code.
- Show the model's understanding to the user.
- Offer better alternatives with tradeoffs.
- Do not proceed to `dev` before user approval.
- Create or update `input.yaml`, `01-plan.md`, and `harness.json` for full-flow work.

## References

- Input schema: `references/input-schema.md`
- Plan template: `references/plan-template.md`
