#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$ROOT/.Codex/skills"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
TARGET_DIR="$CODEX_HOME_DIR/skills"
DRY_RUN=false

usage() {
  cat <<'USAGE'
Usage:
  ./init.sh [--dry-run]

Links bundled Codex skills into:
  ${CODEX_HOME:-$HOME/.codex}/skills

Rules:
  - Creates missing symlinks.
  - Keeps existing symlinks that already point to this repo.
  - Stops on conflicting files/directories/symlinks.
  - Does not delete or overwrite anything.
USAGE
}

real_path() {
  python3 - "$1" <<'PY'
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[init][FAIL] unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -d "$SOURCE_DIR" ]] || { echo "[init][FAIL] missing skills directory: $SOURCE_DIR" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "[init][FAIL] python3 is required" >&2; exit 1; }

if [[ "$DRY_RUN" != true ]]; then
  mkdir -p "$TARGET_DIR"
fi

echo "[init] source: $SOURCE_DIR"
echo "[init] target: $TARGET_DIR"

linked=0
kept=0
conflicts=0

for skill_dir in "$SOURCE_DIR"/*; do
  [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || continue
  skill_name="$(basename "$skill_dir")"
  dest="$TARGET_DIR/$skill_name"

  if [[ -L "$dest" ]]; then
    current_target="$(readlink "$dest")"
    if [[ "$current_target" != /* ]]; then
      current_target="$(cd "$(dirname "$dest")" && cd "$(dirname "$current_target")" && pwd -P)/$(basename "$current_target")"
    fi
    if [[ "$(real_path "$current_target")" == "$(real_path "$skill_dir")" ]]; then
      echo "[init][KEEP] $skill_name -> $skill_dir"
      kept=$((kept + 1))
      continue
    fi
    echo "[init][CONFLICT] $dest points elsewhere: $(readlink "$dest")" >&2
    conflicts=$((conflicts + 1))
    continue
  fi

  if [[ -e "$dest" ]]; then
    echo "[init][CONFLICT] $dest already exists. Not overwriting." >&2
    conflicts=$((conflicts + 1))
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "[init][DRY-RUN] ln -s \"$skill_dir\" \"$dest\""
  else
    ln -s "$skill_dir" "$dest"
    echo "[init][LINK] $skill_name -> $skill_dir"
  fi
  linked=$((linked + 1))
done

if [[ "$conflicts" -gt 0 ]]; then
  echo "[init][FAIL] conflicts=$conflicts linked=$linked kept=$kept" >&2
  echo "[init][INFO] Resolve conflicts manually. This script never deletes files." >&2
  exit 1
fi

echo "[init][OK] linked=$linked kept=$kept target=$TARGET_DIR"
