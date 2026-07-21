#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ROOT="$(harness_resolve_root)"
cd "$ROOT"

fail() { echo "[harness][output-quality][FAIL] $*" >&2; exit 1; }

WORK_DIR="${HARNESS_WORK_DIR:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-dir) WORK_DIR="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 --work-dir docs/work/YYYY-MM-DD-task"; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

[[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] || fail "valid --work-dir required"

python3 - "$WORK_DIR" <<'PY'
from pathlib import Path
import re, sys
work=Path(sys.argv[1])
checks={
 "01-plan.md":{"goal":["goal","목표"],"scope":["scope","범위"],"alternatives":["alternative","대안"],"approval":["approval","approved","동의"],"verification":["verification","검증"]},
 "02-dev-result.md":{"changed files":["changed files","변경 파일"],"reason":["reason","이유"],"test status":["test code","테스트"],"unresolved":["unresolved","deferred","보류","미해결"]},
 "03-test-result.md":{"commands":["command","명령"],"result":["result","passed","failed","결과"],"failure cause":["failure","cause","실패"],"unverified":["unverified","미검증","deferred"]},
 "04-ops-check.md":{"logs":["log","로그"],"secrets":["secret","token","password"],"configuration":["config","environment","profile","설정"],"health":["health","헬스"],"repeated jobs":["scheduler","job","cron","반복"],"external dependency":["external","dependency","timeout","연동"]},
 "05-summary.md":{"summary":["summary","요약"],"operational impact":["operational","운영"],"remaining risk":["risk","리스크"],"docs":["docs","documentation","문서"]},
}
# Placeholder = an explicitly unfinished FIELD VALUE ("field: TODO", "field: 작성 필요")
# or a line whose entire value is TODO/TBD. Two false positives are deliberately
# avoided: (1) a bare trailing colon (headings/labels legitimately end in ":"),
# and (2) TODO/TBD mentioned in prose ("resolved every TODO") — the value must sit
# after a colon or be the whole line, not appear anywhere in a sentence.
placeholder=re.compile(r"(:\s*TODO\b|:\s*TBD\b|:\s*미작성|:\s*작성\s*필요|^(TODO|TBD)\s*$)", re.I)
accepted=re.compile(r"(none|not applicable|n/a|unverified|deferred|없음|해당\s*없음|미검증|보류)", re.I)
errors=[]    # blocking: missing/empty file, placeholder value
warnings=[]  # non-blocking: a required meaning keyword was not found
for filename, fields in checks.items():
    path=work/filename
    if not path.exists() or path.stat().st_size == 0:
        errors.append(f"{filename}: missing or empty")
        continue
    text=path.read_text(encoding="utf-8").lower()
    for field, words in fields.items():
        if not any(w.lower() in text for w in words):
            warnings.append(f"{filename}: missing meaning - {field}")
    for no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        s=line.strip()
        if s and not accepted.search(s) and placeholder.search(s):
            errors.append(f"{filename}:{no}: placeholder value - {s}")
if warnings:
    print("[harness][output-quality][WARN] some expected meanings were not found (non-blocking)")
    for w in warnings: print("  -", w)
if errors:
    print("[harness][output-quality][FAIL] quality check failed")
    for e in errors: print("  -", e)
    raise SystemExit(1)
print("[harness][output-quality][OK] no placeholder/empty outputs")
PY
