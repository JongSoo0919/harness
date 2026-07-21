#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ROOT="$(harness_resolve_root)"
cd "$ROOT"

fail() { echo "[harness][stage][FAIL] $*" >&2; exit 1; }

WORK_DIR=""
STAGE=""
OVERRIDE=false
REASON=""
RISK=""
APPROVED_BY=""
USER_REASON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-dir) WORK_DIR="${2:-}"; shift 2 ;;
    --stage) STAGE="${2:-}"; shift 2 ;;
    --override-approved) OVERRIDE=true; shift ;;
    --override-reason) REASON="${2:-}"; shift 2 ;;
    --override-risk) RISK="${2:-}"; shift 2 ;;
    --approved-by) APPROVED_BY="${2:-}"; shift 2 ;;
    --user-decision-reason) USER_REASON="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 --work-dir docs/work/task --stage dev|test|ops|document|share|pr"; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

[[ -n "$WORK_DIR" && -n "$STAGE" ]] || fail "--work-dir and --stage required"
[[ -f "$WORK_DIR/harness.json" ]] || fail "missing harness.json"

python3 - "$WORK_DIR/harness.json" "$STAGE" "$OVERRIDE" "$REASON" "$RISK" "$APPROVED_BY" "$USER_REASON" <<'PY'
import json, sys
from datetime import datetime, timezone
path, stage, override_raw, reason, risk, approved_by, user_reason = sys.argv[1:8]
override=override_raw == "true"
data=json.load(open(path, encoding="utf-8"))
rules={
 "dev":["inputReady","planApproved"],
 "test":["inputReady","planApproved","devDone"],
 "ops":["inputReady","planApproved","devDone","testPassed"],
 "document":["inputReady","planApproved","devDone","testPassed","opsPassed"],
 "share":["inputReady","planApproved","devDone","testPassed","opsPassed","documentDone"],
 "pr":["inputReady","planApproved","devDone","testPassed","opsPassed","documentDone","shareApproved"],
}
if stage not in rules:
    raise SystemExit(f"[harness][stage][FAIL] unknown stage: {stage}")
missing=[k for k in rules[stage] if data.get(k) is not True]
# Two risk channels:
#   openRisks[]     -> unresolved, BLOCKING. Must be cleared or human-overridden.
#   acceptedRisks[] -> knowingly accepted, NON-BLOCKING. Each item should carry a
#                      reason and approvedBy. This exists so real residual risk is
#                      recorded honestly instead of being hidden to get past the gate.
open_risks=data.get("openRisks")
accepted_risks=data.get("acceptedRisks") or []
# A non-list acceptedRisks (scalar/dict) is itself malformed — wrap it so it is
# reported as a clean BLOCKED entry instead of crashing the `for` loop below.
if not isinstance(accepted_risks, list):
    accepted_risks=[accepted_risks]
has_open=open_risks not in ([], None)
# An acceptedRisks entry only counts as a real, non-blocking acceptance if it
# carries a reason AND an approvedBy as non-empty strings. Bare strings, missing
# fields, or non-string values (null/true/123) are malformed and BLOCK —
# otherwise "move it to acceptedRisks" becomes a bypass the model could self-approve.
def _str(v):
    return isinstance(v, str) and v.strip()
def _ok(r):
    return isinstance(r, dict) and _str(r.get("reason")) and _str(r.get("approvedBy"))
malformed=[r for r in accepted_risks if not _ok(r)]
if missing or has_open or malformed:
    print(f"[harness][stage][BLOCKED] {stage}")
    if missing: print("- missing/false:", ", ".join(missing))
    if has_open: print("- openRisks (blocking):", open_risks)
    if malformed: print("- acceptedRisks missing reason/approvedBy (blocking):", malformed)
    print("- options: return to a previous stage, complete the missing output,")
    print("  give each acceptedRisks[] item a reason + approvedBy,")
    print("  or request a human override.")
    if stage == "pr" and "shareApproved" in missing:
        raise SystemExit("[harness][stage][FAIL] pr cannot be overridden without shareApproved")
    if not override:
        raise SystemExit(1)
    if not all([reason, risk, approved_by, user_reason]):
        raise SystemExit("[harness][stage][FAIL] override requires reason, risk, approved-by, and user-decision-reason")
    data.setdefault("overrides", []).append({
      "stage":stage,"missing":missing,"openRisks":open_risks or [],
      "reason":reason,"riskAccepted":risk,"approvedBy":approved_by,
      "userDecisionReason":user_reason,"approvedAt":datetime.now(timezone.utc).isoformat()
    })
    json.dump(data, open(path,"w",encoding="utf-8"), ensure_ascii=False, indent=2)
    open(path,"a",encoding="utf-8").write("\n")
    print(f"[harness][stage][OVERRIDE] {stage}")
else:
    if accepted_risks:
        print(f"[harness][stage][INFO] acceptedRisks (non-blocking): {len(accepted_risks)} recorded")
        for r in accepted_risks: print("  -", r)
    print(f"[harness][stage][OK] {stage}")
PY
