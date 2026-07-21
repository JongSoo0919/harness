#!/usr/bin/env bash
set -euo pipefail

WORK_DIR=""; WIKI_DIR="docs/wiki/drafts"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-dir) WORK_DIR="${2:-}"; shift 2 ;;
    --wiki-dir) WIKI_DIR="${2:-}"; shift 2 ;;
    -h|--help) echo "Usage: $0 --work-dir docs/work/task"; exit 0 ;;
    *) echo "[harness][wiki-extract][FAIL] unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$WORK_DIR" ]] || { echo "[harness][wiki-extract][FAIL] --work-dir required" >&2; exit 1; }
TARGET="$WIKI_DIR/$(basename "$WORK_DIR")"
for f in index.md operation.md development.md onboarding.md; do
  [[ -s "$TARGET/$f" ]] || { echo "[harness][wiki-extract][FAIL] missing: $TARGET/$f" >&2; exit 1; }
done
if grep -R -E -i "(password|passwd|pwd|secret|token|api[_-]?key|private[_-]?key)\s*[:=]\s*[^,\s\[]" "$TARGET" >/dev/null 2>&1; then
  echo "[harness][wiki-extract][FAIL] secret-like value in wiki draft" >&2
  exit 1
fi
echo "[harness][wiki-extract][OK] drafts verified"
