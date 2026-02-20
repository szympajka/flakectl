#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../scripts/lib.sh"

PASS=0
FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}✓${NC} %s\n" "$label"
  else
    FAIL=$((FAIL + 1))
    printf "  ${RED}✗${NC} %s\n" "$label"
    printf "    expected: %s\n" "$expected"
    printf "    actual:   %s\n" "$actual"
  fi
}

# --- infer_scope ---

describe_infer_scope() {
  echo ""
  echo "infer_scope"

  assert_eq "deep nesting uses parent dir" \
    "homebrew" \
    "$(infer_scope "modules/darwin/homebrew/casks.nix")"

  assert_eq "module direct child uses parent dir" \
    "darwin" \
    "$(infer_scope "modules/darwin/services.nix")"

  assert_eq "apps uses parent dir" \
    "aarch64-darwin" \
    "$(infer_scope "apps/aarch64-darwin/build-switch")"

  assert_eq "scripts uses parent dir" \
    "updaters" \
    "$(infer_scope "scripts/updaters/foo.sh")"

  assert_eq "root nix file uses basename without extension" \
    "flake" \
    "$(infer_scope "flake.nix")"

  assert_eq "root non-nix file uses full basename" \
    "README.md" \
    "$(infer_scope "README.md")"

  assert_eq "single-level dir uses dir name" \
    "docs" \
    "$(infer_scope "docs/guide.md")"
}

# --- suggest_commit_message ---

describe_suggest_commit_message() {
  echo ""
  echo "suggest_commit_message"

  assert_eq "single file, single scope" \
    "chore(homebrew): update casks" \
    "$(suggest_commit_message "modules/darwin/homebrew/casks.nix")"

  assert_eq "multiple files, same scope" \
    "chore(homebrew): update brews, casks" \
    "$(suggest_commit_message "modules/darwin/homebrew/casks.nix
modules/darwin/homebrew/brews.nix")"

  assert_eq "multiple files, different scopes omits scope" \
    "chore: update build, casks" \
    "$(suggest_commit_message "modules/darwin/homebrew/casks.nix
apps/aarch64-darwin/build")"

  assert_eq "root file scope" \
    "chore(flake): update flake" \
    "$(suggest_commit_message "flake.nix")"

  assert_eq "strips .nix extension from subjects" \
    "chore(darwin): update services" \
    "$(suggest_commit_message "modules/darwin/services.nix")"

  assert_eq "non-nix files keep extension in subject" \
    "chore(docs): update guide.md" \
    "$(suggest_commit_message "docs/guide.md")"
}

# --- run ---

main() {
  describe_infer_scope
  describe_suggest_commit_message

  echo ""
  printf "Results: ${GREEN}%d passed${NC}" "$PASS"
  if [ "$FAIL" -gt 0 ]; then
    printf ", ${RED}%d failed${NC}" "$FAIL"
  fi
  echo ""

  [ "$FAIL" -eq 0 ]
}

main
