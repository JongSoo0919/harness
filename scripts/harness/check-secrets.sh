#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ROOT="$(harness_resolve_root)"
cd "$ROOT"

fail() { echo "[harness][secret][FAIL] $*" >&2; exit 1; }
warn() { echo "[harness][secret][WARN] $*" >&2; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not a git repository"

files=()
while IFS= read -r f; do [[ -n "$f" ]] && files+=("$f"); done < <(git diff --cached --name-only --diff-filter=ACMR || true)
while IFS= read -r f; do [[ -n "$f" ]] && files+=("$f"); done < <(git diff --name-only --diff-filter=ACMR || true)
while IFS= read -r f; do [[ -n "$f" ]] && files+=("$f"); done < <(git ls-files --others --exclude-standard || true)

blocked='(^|/)(\.env($|\.)|secret/|secrets/|.*\.pem$|.*\.key$|.*\.p12$|.*\.jks$|.*\.keystore$|.*id_rsa.*|.*id_ed25519.*|.*credentials.*|.*credential.*|.*token.*|.*password.*)'
allowed='(^|/)(\.env\.example|.*\.example$|.*\.template$|.*\.sample$|.*README\.md$|.*\.md$)'

for f in "${files[@]:-}"; do
  if [[ "$f" =~ $blocked && ! "$f" =~ $allowed ]]; then
    fail "secret-like file in changes: $f"
  fi
done

tracked_secret_files=()
while IFS= read -r f; do
  if [[ "$f" =~ $blocked && ! "$f" =~ $allowed ]]; then
    tracked_secret_files+=("$f")
  fi
done < <(git ls-files || true)

diff_content="$(git diff --cached --unified=0 --no-ext-diff -- . ':(exclude)scripts/harness/check-secrets.sh' || true)"
[[ -n "$diff_content" ]] || diff_content="$(git diff --unified=0 --no-ext-diff -- . ':(exclude)scripts/harness/check-secrets.sh' || true)"
secret_value='(^\+.*(password|passwd|pwd|secret|token|api[_-]?key|access[_-]?key|secret[_-]?key|private[_-]?key|client[_-]?secret)[[:space:]]*[:=][[:space:]]*["'\'']?[^"'\'']{4,})|(^\+.*-----BEGIN (RSA |OPENSSH |EC |DSA |)PRIVATE KEY-----)'

if printf '%s\n' "$diff_content" | grep -E -i "$secret_value" >/dev/null 2>&1; then
  printf '%s\n' "$diff_content" | grep -E -i "$secret_value" >&2 || true
  fail "secret-like value found in diff"
fi

if [[ "${#tracked_secret_files[@]}" -gt 0 ]]; then
  warn "tracked secret-like files exist and cannot be validated automatically:"
  printf '  - %s\n' "${tracked_secret_files[@]}" >&2
fi
echo "[harness][secret][OK] no secret risk detected"
