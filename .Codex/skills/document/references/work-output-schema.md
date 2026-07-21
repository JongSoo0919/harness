# Work Output Schema

Full-flow work uses:

```text
docs/work/YYYY-MM-DD-task/
├── input.yaml
├── 01-plan.md
├── 02-dev-result.md
├── 03-test-result.md
├── 04-ops-check.md
├── 05-summary.md
└── harness.json
```

`harness.json`:

```json
{
  "task": "",
  "currentStage": "plan",
  "inputReady": false,
  "planApproved": false,
  "devDone": false,
  "testPassed": false,
  "opsPassed": false,
  "documentDone": false,
  "shareApproved": false,
  "branch": "",
  "openRisks": [],
  "acceptedRisks": [],
  "overrides": [],
  "updatedAt": ""
}
```

`openRisks[]` are unresolved and block stage entry. `acceptedRisks[]` are knowingly
accepted, non-blocking, and each entry must be an object with a `reason` and an
`approvedBy` (e.g. `{ "risk": "...", "reason": "...", "approvedBy": "..." }`).

Stage gates:

| Stage | Required |
| --- | --- |
| `dev` | `inputReady`, `planApproved` |
| `test` | `inputReady`, `planApproved`, `devDone` |
| `ops` | `inputReady`, `planApproved`, `devDone`, `testPassed` |
| `document` | `inputReady`, `planApproved`, `devDone`, `testPassed`, `opsPassed` |
| `share` | `inputReady`, `planApproved`, `devDone`, `testPassed`, `opsPassed`, `documentDone` |
| `pr` | share requirements plus `shareApproved` |

`run-gates.sh --work-dir docs/work/YYYY-MM-DD-task --stage dev` checks only stage entry state. Complete output quality checks run when `--require-work-output` is passed, when no stage is specified with `--work-dir`, or when stage is `share`/`pr`.

Output quality checks:

| File | Required meaning |
| --- | --- |
| `01-plan.md` | goal, scope, alternatives, user approval, verification |
| `02-dev-result.md` | changed files, reason, test code status, unresolved items |
| `03-test-result.md` | commands, result, failure cause, unverified reason |
| `04-ops-check.md` | logs, secrets, configuration, health, scheduler/repeated jobs, external dependency |
| `05-summary.md` | final summary, operational impact, remaining risk, docs updated |
