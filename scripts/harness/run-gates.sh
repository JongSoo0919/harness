#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ROOT="$(harness_resolve_root)"
cd "$ROOT"

WORK_DIR=""
REQUIRE_WORK_OUTPUT=false
STAGE=""
WIKI_DIR="docs/wiki/drafts"
RUN_DIR="${HARNESS_RUN_DIR:-}"
NO_RUN_LOG=false
OVERRIDE_ARGS=()

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness/run-gates.sh [--work-dir docs/work/YYYY-MM-DD-task] [--require-work-output] [--wiki-dir docs/wiki/drafts] [--stage dev|test|ops|document|share|pr] [--run-dir .harness/runs/...]

Runs secret, output, build/test, wiki, and stage gates.

Notes:
  --stage dev/test/ops/document checks stage state only.
  --require-work-output checks complete final outputs.
  --stage share/pr also checks complete final outputs.
  The build/test gate runs on --stage test/share/pr or --require-work-output.
  Failure lessons are NOT collected automatically; run collect-lessons.sh manually
  when you want to review recorded failures.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-dir) WORK_DIR="${2:-}"; shift 2 ;;
    --require-work-output) REQUIRE_WORK_OUTPUT=true; shift ;;
    --wiki-dir) WIKI_DIR="${2:-}"; shift 2 ;;
    --stage) STAGE="${2:-}"; shift 2 ;;
    --run-dir) RUN_DIR="${2:-}"; shift 2 ;;
    --no-run-log) NO_RUN_LOG=true; shift ;;
    --override-approved) OVERRIDE_ARGS+=("--override-approved"); shift ;;
    --override-reason) OVERRIDE_ARGS+=("--override-reason" "${2:-}"); shift 2 ;;
    --override-risk) OVERRIDE_ARGS+=("--override-risk" "${2:-}"); shift 2 ;;
    --approved-by) OVERRIDE_ARGS+=("--approved-by" "${2:-}"); shift 2 ;;
    --user-decision-reason) OVERRIDE_ARGS+=("--user-decision-reason" "${2:-}"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[harness][FAIL] unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ "$NO_RUN_LOG" != true ]]; then
  if [[ -z "$RUN_DIR" ]]; then
    if [[ -n "$WORK_DIR" ]]; then RUN_DIR="$(scripts/harness/init-run.sh --work-dir "$WORK_DIR")"; else RUN_DIR="$(scripts/harness/init-run.sh --task run-gates)"; fi
  else
    mkdir -p "$RUN_DIR"; [[ -f "$RUN_DIR/gates.log" ]] || printf '# gates.log\n' > "$RUN_DIR/gates.log"; [[ -f "$RUN_DIR/errors.log" ]] || printf '# errors.log\n' > "$RUN_DIR/errors.log"
  fi
  export HARNESS_RUN_DIR="$RUN_DIR"
  exec > >(tee -a "$RUN_DIR/gates.log") 2>&1
  echo "[harness][run][START] $RUN_DIR"
  trap 's=$?; scripts/harness/log-error.sh --run-dir "$RUN_DIR" --stage "${STAGE:-gates}" --error "run-gates failed with status $s" --cause "Check the first FAIL or BLOCKED line in gates.log. If caused by a model assumption, record the assumption and update the rule." >/dev/null 2>&1 || true; echo "[harness][run][FAIL] $RUN_DIR"; exit $s' ERR
fi

scripts/harness/check-secrets.sh

RUN_FULL_OUTPUT=false
if [[ "$REQUIRE_WORK_OUTPUT" == true || ( -n "$WORK_DIR" && -z "$STAGE" ) || "$STAGE" == "share" || "$STAGE" == "pr" ]]; then
  RUN_FULL_OUTPUT=true
fi

# Build/test gate FIRST, so testPassed is set by execution before the output
# gates read it. Runs on --stage test, or on any final-output verification
# (share/pr, --require-work-output, or a bare --work-dir). Same trigger set as
# RUN_FULL_OUTPUT plus the standalone test stage — no path validates final
# outputs without also running the build/test gate.
if [[ "$STAGE" == "test" || "$RUN_FULL_OUTPUT" == true ]]; then
  if [[ -n "$WORK_DIR" ]]; then
    scripts/harness/check-build.sh --work-dir "$WORK_DIR"
  else
    scripts/harness/check-build.sh
  fi
else
  echo "[harness][build][SKIP] build/test gate not requested (runs on --stage test/share/pr or --require-work-output)"
fi

if [[ "$RUN_FULL_OUTPUT" == true ]]; then
  [[ -n "$WORK_DIR" ]] || { echo "[harness][work-output][FAIL] --require-work-output needs --work-dir" >&2; exit 1; }
  scripts/harness/check-work-outputs.sh --work-dir "$WORK_DIR"
  scripts/harness/check-output-quality.sh --work-dir "$WORK_DIR"
  scripts/harness/extract-wiki-notes.sh --work-dir "$WORK_DIR" --wiki-dir "$WIKI_DIR"
  scripts/harness/check-wiki-extract.sh --work-dir "$WORK_DIR" --wiki-dir "$WIKI_DIR"
else
  echo "[harness][work-output][SKIP] final output gate not requested"
  echo "[harness][output-quality][SKIP] final output gate not requested"
  echo "[harness][wiki-extract][SKIP] final output gate not requested"
fi

if [[ -n "$STAGE" ]]; then
  [[ -n "$WORK_DIR" ]] || { echo "[harness][stage][FAIL] --stage requires --work-dir" >&2; exit 1; }
  if [[ "${#OVERRIDE_ARGS[@]}" -gt 0 ]]; then
    scripts/harness/check-stage-allowed.sh --work-dir "$WORK_DIR" --stage "$STAGE" "${OVERRIDE_ARGS[@]}"
  else
    scripts/harness/check-stage-allowed.sh --work-dir "$WORK_DIR" --stage "$STAGE"
  fi
else
  echo "[harness][stage][SKIP] --stage not set"
fi

echo "[harness][OK] all gates passed"
if [[ -n "$RUN_DIR" ]]; then
  python3 - "$RUN_DIR/run.json" <<'PY'
import json, sys
from datetime import datetime, timezone
path=sys.argv[1]
try: data=json.load(open(path, encoding="utf-8"))
except FileNotFoundError: data={}
data["status"]="passed"; data["endedAt"]=datetime.now(timezone.utc).isoformat()
json.dump(data, open(path,"w",encoding="utf-8"), ensure_ascii=False, indent=2)
open(path,"a",encoding="utf-8").write("\n")
PY
  echo "[harness][run][OK] $RUN_DIR"
fi
