#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir) RUN_DIR="${2:-}"; shift 2 ;;
    --) shift; break ;;
    -h|--help) echo "Usage: $0 --run-dir .harness/runs/... -- command"; exit 0 ;;
    *) echo "[harness][command][FAIL] unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$RUN_DIR" && $# -gt 0 ]] || { echo "[harness][command][FAIL] --run-dir and command required" >&2; exit 1; }
mkdir -p "$RUN_DIR"
printf '\n[%s] START command=%q\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$RUN_DIR/commands.log"
set +e
"$@"
status=$?
set -e
printf '[%s] END status=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$status" >> "$RUN_DIR/commands.log"
exit "$status"
