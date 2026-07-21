#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=""; STAGE="manual"; DECISION=""; REASON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir) RUN_DIR="${2:-}"; shift 2 ;;
    --stage) STAGE="${2:-manual}"; shift 2 ;;
    --decision) DECISION="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 --run-dir .harness/runs/... --decision text [--reason text]"; exit 0 ;;
    *) echo "[harness][decision][FAIL] unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$RUN_DIR" && -n "$DECISION" ]] || { echo "[harness][decision][FAIL] --run-dir and --decision required" >&2; exit 1; }
mkdir -p "$RUN_DIR"
{
  echo ""
  echo "## $(date -u +%Y-%m-%dT%H:%M:%SZ) $STAGE"
  echo "- decision: $DECISION"
  echo "- reason: ${REASON:-not recorded}"
} >> "$RUN_DIR/decisions.md"
echo "[harness][decision][OK] $RUN_DIR/decisions.md"
