#!/usr/bin/env bash
set -euo pipefail

FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) FILE="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 --file docs/wiki/<category>/<file>.md"; exit 0 ;;
    *) echo "[harness][wiki-promotion][FAIL] unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$FILE" && -f "$FILE" ]] || { echo "[harness][wiki-promotion][FAIL] valid --file required" >&2; exit 1; }
[[ "$FILE" == docs/wiki/operation/* || "$FILE" == docs/wiki/development/* || "$FILE" == docs/wiki/onboarding/* || "$FILE" == docs/wiki/lessons/* ]] || { echo "[harness][wiki-promotion][FAIL] final wiki path required" >&2; exit 1; }

python3 - "$FILE" <<'PY'
from pathlib import Path
import re, sys
path=Path(sys.argv[1]); text=path.read_text(encoding="utf-8")
errors=[]
m=re.match(r"^---\n(.*?)\n---\n", text, re.S)
meta={}
if not m:
    errors.append("missing frontmatter")
else:
    for line in m.group(1).splitlines():
        if ":" in line:
            k,v=line.split(":",1); meta[k.strip()]=v.strip()
required={"source":r"^docs/work/.+","reviewer":r".+","reviewedAt":r"^\d{4}-\d{2}-\d{2}$","approval":r"^approved$","category":r"^(operation|development|onboarding|lessons)$"}
for k,p in required.items():
    if not re.match(p, meta.get(k,"")):
        errors.append(f"invalid metadata: {k}")
category=meta.get("category")
if category and f"docs/wiki/{category}/" not in str(path):
    errors.append("category does not match path")
if "Auto-extracted draft" in text or "Human review required before promotion" in text:
    errors.append("draft marker remains")
if re.search(r"-----BEGIN [A-Z ]*PRIVATE KEY-----", text) or re.search(r"(password|passwd|pwd|secret|token|api[_-]?key|private[_-]?key)\s*[:=]\s*[^,\s\[]+", text, re.I):
    errors.append("secret-like value detected")
body=text[m.end():].strip() if m else text.strip()
if len(body) < 80:
    errors.append("body too short for final wiki")
if errors:
    print("[harness][wiki-promotion][FAIL]")
    for e in errors: print("  -", e)
    raise SystemExit(1)
print("[harness][wiki-promotion][OK] manually promoted wiki is valid")
PY
