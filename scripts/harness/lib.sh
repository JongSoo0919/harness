#!/usr/bin/env bash
# Shared helpers for harness scripts.
#
# harness_resolve_root: resolve the repository root, hard-failing (exit 2) if the
# script is not run inside a git work tree. This replaces the old
#   ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# pattern, whose `|| pwd` fallback silently ran gates from the wrong directory
# (e.g. a subfolder or an unrelated cwd) and let checks pass against nothing.

harness_resolve_root() {
  local root
  if ! root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    echo "[harness][FAIL] not inside a git repository — run harness scripts from within the project repo." >&2
    exit 2
  fi
  printf '%s\n' "$root"
}
