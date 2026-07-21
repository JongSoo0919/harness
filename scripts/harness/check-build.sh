#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ROOT="$(harness_resolve_root)"
cd "$ROOT"

fail() { echo "[harness][build][FAIL] $*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Usage:
  scripts/harness/check-build.sh [--work-dir docs/work/YYYY-MM-DD-task]

Proves the code works by execution, not by the model writing testPassed by hand.
harness.json.testPassed=true is recorded ONLY when a TEST step actually ran and
passed. A build-only run (no test target) does NOT set testPassed.

Build command resolution (first match wins):
  1. $HARNESS_BUILD_CMD   environment variable (treated as the authoritative test)
  2. .harness/build.sh    project-provided hook (treated as the authoritative test)
  3. auto-detect          node / gradle / maven / go / rust / python / make
If nothing is detected, the gate skips (exit 0).
USAGE
}

WORK_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-dir) WORK_DIR="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

# NOTE: watch-mode test runners are neutralized per-command (CI=1 on the node
# test invocation below) rather than by a global `export CI=1`, because a global
# CI=1 changes build behavior too (e.g. CRA/Vue `npm run build` promotes lint
# warnings to errors and would fail builds that otherwise pass).

# Bounded run (coreutils timeout if available; macOS may only have gtimeout).
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then TIMEOUT_BIN="gtimeout"; fi
if [[ -z "$TIMEOUT_BIN" ]]; then
  echo "[harness][build][WARN] no timeout/gtimeout found — build/test runs are NOT time-bounded (install coreutils for a hard cap)"
fi
# stdin from /dev/null so a prompt/watch runner cannot block the gate.
run_bounded() { local secs="$1"; shift; if [[ -n "$TIMEOUT_BIN" ]]; then "$TIMEOUT_BIN" "$secs" "$@" </dev/null; else "$@" </dev/null; fi; }

run_cmd() { # run_cmd <label> <shell-command-string>
  echo "[harness][build][INFO] $1"
  if ! run_bounded 900 bash -c "$2"; then fail "$1 failed (see output above)"; fi
}

ran=false        # any build OR test step executed
tests_ran=false  # a TEST step actually executed (this alone may set testPassed)

if [[ -n "${HARNESS_BUILD_CMD:-}" ]]; then
  run_cmd "HARNESS_BUILD_CMD" "$HARNESS_BUILD_CMD"; ran=true; tests_ran=true
elif [[ -f .harness/build.sh ]]; then
  run_cmd ".harness/build.sh" "sh .harness/build.sh"; ran=true; tests_ran=true
else
  # Best-effort auto-detect for common ecosystems. Each detector is guarded by
  # tool availability so a missing toolchain skips instead of failing.
  if [[ -f package.json ]] && command -v node >/dev/null 2>&1; then
    pm="npm"
    if [[ -f pnpm-lock.yaml ]] && command -v pnpm >/dev/null 2>&1; then pm="pnpm"
    elif [[ -f yarn.lock ]] && command -v yarn >/dev/null 2>&1; then pm="yarn"; fi
    if node -e 'process.exit(((require("./package.json").scripts)||{}).build?0:1)' 2>/dev/null; then
      run_cmd "$pm run build" "$pm run build"; ran=true
    fi
    if node -e 'process.exit(((require("./package.json").scripts)||{}).test?0:1)' 2>/dev/null; then
      # CI=1 only here: makes react-scripts/vitest run once instead of watching.
      run_cmd "$pm test" "CI=1 $pm test"; ran=true; tests_ran=true
    fi
  fi
  if [[ -f gradlew ]]; then
    run_cmd "./gradlew test" "./gradlew --offline test -q || ./gradlew test -q"; ran=true; tests_ran=true
  elif [[ -f pom.xml ]] && command -v mvn >/dev/null 2>&1; then
    run_cmd "mvn test" "mvn -q -B test"; ran=true; tests_ran=true
  fi
  if [[ -f go.mod ]] && command -v go >/dev/null 2>&1; then
    run_cmd "go build/test" "go build ./... && go test ./..."; ran=true; tests_ran=true
  fi
  if [[ -f Cargo.toml ]] && command -v cargo >/dev/null 2>&1; then
    run_cmd "cargo test" "cargo test --quiet"; ran=true; tests_ran=true
  fi
  if { [[ -f pyproject.toml ]] || [[ -f setup.py ]] || [[ -f pytest.ini ]]; } && command -v pytest >/dev/null 2>&1; then
    run_cmd "pytest" "pytest -q"; ran=true; tests_ran=true
  fi
  if [[ "$ran" != true && -f Makefile ]] && grep -qE '^test:' Makefile 2>/dev/null && command -v make >/dev/null 2>&1; then
    run_cmd "make test" "make test"; ran=true; tests_ran=true
  fi
fi

if [[ "$ran" != true ]]; then
  echo "[harness][build][SKIP] no build/test target detected (set HARNESS_BUILD_CMD or add .harness/build.sh)"
  exit 0
fi

if [[ "$tests_ran" != true ]]; then
  echo "[harness][build][WARN] a build ran but NO tests were executed — testPassed left unset (add a test target or set HARNESS_BUILD_CMD to prove tests)"
  exit 0
fi

# Tests actually ran and passed -> record testPassed by execution (not self-report).
if [[ -n "$WORK_DIR" && -f "$WORK_DIR/harness.json" ]]; then
  python3 - "$WORK_DIR/harness.json" <<'PY'
import json, sys
p = sys.argv[1]
with open(p, encoding="utf-8") as f:
    d = json.load(f)
d["testPassed"] = True
with open(p, "w", encoding="utf-8") as f:
    json.dump(d, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
  echo "[harness][build][OK] tests passed -> harness.json.testPassed=true"
elif [[ -n "$WORK_DIR" ]]; then
  echo "[harness][build][WARN] tests passed but $WORK_DIR/harness.json not found — testPassed not recorded"
else
  echo "[harness][build][OK] tests passed"
fi
