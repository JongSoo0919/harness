#!/usr/bin/env bash
set -euo pipefail

WORK_DIR=""; WIKI_DIR="docs/wiki/drafts"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-dir) WORK_DIR="${2:-}"; shift 2 ;;
    --wiki-dir) WIKI_DIR="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 --work-dir docs/work/task [--wiki-dir docs/wiki/drafts]"; exit 0 ;;
    *) echo "[harness][wiki-extract][FAIL] unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] || { echo "[harness][wiki-extract][FAIL] valid --work-dir required" >&2; exit 1; }

TASK="$(basename "$WORK_DIR")"
TARGET="$WIKI_DIR/$TASK"
mkdir -p "$TARGET"

python3 - "$WORK_DIR" "$TARGET" "$TASK" <<'PY'
from pathlib import Path
from datetime import datetime, timezone
import re, sys
work=Path(sys.argv[1]); target=Path(sys.argv[2]); task=sys.argv[3]
files=["01-plan.md","02-dev-result.md","03-test-result.md","04-ops-check.md","05-summary.md"]
groups={
 "operation.md":["ops","log","health","config","environment","scheduler","external","timeout","rollback","운영","로그","헬스","설정","배포","리스크"],
 "development.md":["dev","code","api","database","permission","exception","test","architecture","개발","코드","테스트","검증"],
 "onboarding.md":["goal","workflow","decision","policy","term","user","scope","목표","흐름","결정","정책","용어"],
}
secret=re.compile(r"(password|passwd|pwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|client[_-]?secret)\s*[:=]\s*[^,\s]+", re.I)
def redact(s): return secret.sub(lambda m: f"{m.group(1)}=[REDACTED]", s)
def collect(words):
    out=[]
    for name in files:
        p=work/name
        if not p.exists(): continue
        for i,line in enumerate(p.read_text(encoding="utf-8").splitlines(),1):
            if any(w.lower() in line.lower() for w in words):
                out.append((name,i,redact(line.strip())))
    return out
for filename, words in groups.items():
    items=collect(words)
    with (target/filename).open("w",encoding="utf-8") as f:
        f.write(f"# {filename.removesuffix('.md').title()} Wiki Draft\n\n")
        f.write("> Auto-extracted draft. Human review required before promotion.\n\n")
        f.write(f"- task: `{task}`\n- source: `{work}`\n- created: `{datetime.now(timezone.utc).isoformat()}`\n\n")
        f.write("## Extracted Notes\n\n")
        if not items: f.write("- none detected\n")
        for src,no,line in items: f.write(f"- `{src}:{no}` {line}\n")
with (target/"index.md").open("w",encoding="utf-8") as f:
    f.write(f"# Wiki Draft Index\n\n- task: `{task}`\n- source: `{work}`\n\n")
    f.write("- `operation.md`\n- `development.md`\n- `onboarding.md`\n")
print(f"[harness][wiki-extract][OK] {target}")
PY
