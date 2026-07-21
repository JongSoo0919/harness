#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ROOT="$(harness_resolve_root)"
cd "$ROOT"

TASK="manual"
WORK_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --task) TASK="${2:-manual}"; shift 2 ;;
    --work-dir) WORK_DIR="${2:-}"; TASK="$(basename "$WORK_DIR")"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--task name] [--work-dir docs/work/task]"; exit 0 ;;
    *) echo "[harness][run][FAIL] unknown option: $1" >&2; exit 1 ;;
  esac
done

SLUG="$(printf '%s' "$TASK" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//')"
[[ -n "$SLUG" ]] || SLUG="manual"
RUN_DIR=".harness/runs/$(date +%Y%m%d-%H%M%S)-$SLUG"
mkdir -p "$RUN_DIR"
printf '# commands.log\n' > "$RUN_DIR/commands.log"
printf '# gates.log\n' > "$RUN_DIR/gates.log"
printf '# errors.log\n' > "$RUN_DIR/errors.log"
printf '# Decisions\n' > "$RUN_DIR/decisions.md"
python3 - "$RUN_DIR/run.json" "$RUN_DIR" "$TASK" "$WORK_DIR" <<'PY'
import json, sys
from datetime import datetime, timezone
path, run_dir, task, work_dir = sys.argv[1:5]
json.dump({"runDir":run_dir,"task":task,"workDir":work_dir,"status":"running","startedAt":datetime.now(timezone.utc).isoformat(),"endedAt":"","assumptionFailures":[]}, open(path,"w",encoding="utf-8"), indent=2)
open(path,"a",encoding="utf-8").write("\n")
PY
echo "$RUN_DIR"
