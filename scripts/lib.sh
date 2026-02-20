#!/usr/bin/env bash
# Shared helpers for nix-apps scripts.
# Sourced automatically — do not run directly.

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

info()    { printf "${YELLOW}%s${NC}\n" "$*"; }
success() { printf "${GREEN}%s${NC}\n" "$*"; }
error()   { printf "${RED}%s${NC}\n" "$*"; }

require_flake() {
  if [ ! -f "flake.nix" ]; then
    error "Error: flake.nix not found in current directory"
    exit 1
  fi
}

# Platform-aware rebuild command.
rebuild_cmd() {
  case "${NIXAPPS_PLATFORM:-}" in
    darwin) echo "/run/current-system/sw/bin/darwin-rebuild" ;;
    nixos)  echo "sudo nixos-rebuild" ;;
    *)      error "Unknown platform: ${NIXAPPS_PLATFORM:-unset}"; exit 1 ;;
  esac
}

# --- Git commit suggestion helpers ---

# Infer scope from a file path: parent directory name for nested files, basename for root files.
infer_scope() {
  local path="$1"
  case "$path" in
    */*) basename "$(dirname "$path")" ;;
    *)   basename "$path" .nix ;;
  esac
}

suggest_commit_message() {
  local changed="$1"
  local scopes scope subjects

  scopes=$(while IFS= read -r f; do infer_scope "$f"; done <<< "$changed" | sort -u)

  if [ "$(echo "$scopes" | wc -l | tr -d ' ')" -eq 1 ] && [ -n "$scopes" ]; then
    scope="(${scopes})"
  else
    scope=""
  fi

  subjects=$(echo "$changed" | xargs -n1 basename | sed 's/\.nix$//' | sort -u | paste -sd ', ' -)
  echo "chore${scope}: update ${subjects}"
}

ensure_clean_tree() {
  if git diff --quiet && git diff --cached --quiet; then
    return 0
  fi

  local changed suggested choice msg
  changed=$({ git diff --name-only; git diff --cached --name-only; } | sort -u)
  suggested=$(suggest_commit_message "$changed")

  info "Git tree is dirty. Changed files:"
  echo "$changed" | sed 's/^/  /'
  echo ""
  info "Suggested: ${suggested}"
  echo ""

  choice=$(gum choose --header "What would you like to do?" \
    "Commit with suggested message" \
    "Edit message" \
    "Abort")

  case "$choice" in
    "Commit with suggested message") msg="$suggested" ;;
    "Edit message") msg=$(gum input --value "$suggested" --width 72 --placeholder "commit message") ;;
    *) error "Aborted."; return 1 ;;
  esac

  git add -A
  git commit -m "$msg"
  success "Committed: ${msg}"
  echo ""
}
