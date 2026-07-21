#!/usr/bin/env bash
set -euo pipefail

RUNS_DIR=".harness/runs"
OUT_DIR="docs/wiki/drafts/lessons"
REPORT_DATE="$(date +%Y-%m-%d)"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --runs-dir) RUNS_DIR="${2:-}"; shift 2 ;;
    --out-dir) OUT_DIR="${2:-}"; shift 2 ;;
    --date) REPORT_DATE="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--runs-dir .harness/runs] [--out-dir docs/wiki/drafts/lessons]"; exit 0 ;;
    *) echo "[harness][lessons][FAIL] unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ -d "$RUNS_DIR" ]] || { mkdir -p "$OUT_DIR"; echo "[harness][lessons][SKIP] no runs dir"; exit 0; }
mkdir -p "$OUT_DIR"
python3 - "$RUNS_DIR" "$OUT_DIR/$REPORT_DATE.md" <<'PY'
from pathlib import Path
from collections import Counter, defaultdict
from datetime import datetime, timezone
import re, sys
runs=Path(sys.argv[1]); out=Path(sys.argv[2])
def records(path):
    items=[]; cur={}
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line=raw.strip()
        if not line or line == "# errors.log": continue
        if line.startswith("[") and "stage=" in line:
            if cur: items.append(cur)
            cur={"stage":line.split("stage=",1)[1]}
        elif "=" in line:
            k,v=line.split("=",1); cur[k]=v
    if cur: items.append(cur)
    return items
def classify(r):
    text=" ".join(r.get(k,"") for k in ["stage","error","cause","llmAssumption","ruleUpdate"]).lower()
    if r.get("llmAssumption") and r.get("llmAssumption") != "none": return "model assumption failure"
    if "secret" in text or "token" in text: return "secret risk"
    if "test" in text or "verify" in text: return "test or verification failure"
    if "ops" in text or "health" in text or "scheduler" in text: return "operational risk"
    if "gate" in text or "blocked" in text or "fail" in text: return "gate failure"
    return "other"
all_records=[]
for p in sorted(runs.glob("*/errors.log")):
    for r in records(p):
        r["run"]=str(p.parent); all_records.append(r)
if not all_records:
    print("[harness][lessons][SKIP] no error records")
    raise SystemExit(0)
counts=Counter(classify(r) for r in all_records)
groups=defaultdict(list)
for r in all_records: groups[classify(r)].append(r)
with out.open("w", encoding="utf-8") as f:
    f.write(f"# Harness Lessons Draft - {out.stem}\n\n")
    f.write("> Auto-collected draft. Human review required before promotion.\n\n")
    f.write(f"- created: `{datetime.now(timezone.utc).isoformat()}`\n- input: `{runs}`\n- records: `{len(all_records)}`\n\n")
    f.write("## Summary\n\n")
    if not counts: f.write("- none\n")
    for k,v in counts.most_common(): f.write(f"- {k}: {v}\n")
    f.write("\n## Details\n\n")
    for k in sorted(groups):
        f.write(f"### {k}\n\n")
        for r in groups[k]:
            f.write(f"- run: `{r.get('run','')}`\n  - stage: `{r.get('stage','')}`\n  - error: {r.get('error','')}\n  - cause: {r.get('cause','')}\n")
            if r.get("llmAssumption","none") != "none": f.write(f"  - assumption: {r.get('llmAssumption')}\n")
            if r.get("ruleUpdate","none") != "none": f.write(f"  - rule update: {r.get('ruleUpdate')}\n")
        f.write("\n")
print(f"[harness][lessons][OK] {out}")
PY
