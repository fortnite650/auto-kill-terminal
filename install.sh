#!/usr/bin/env bash
set -euo pipefail

# auto-kill-terminal installer
# https://github.com/nirholas/auto-kill-terminal
#
# Detects existing agent instruction files and appends terminal management rules.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/nirholas/auto-kill-terminal/main/install.sh | bash
#   bash install.sh --dry-run

VERSION="1.0.0"
DRY_RUN=false
FORCE=false
DIR="."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TERMINAL_RULES='## Terminal Management

- **Always use background terminals** (`isBackground: true`) for every command so a terminal ID is returned
- **Always kill the terminal** after the command completes, whether it succeeds or fails — never leave terminals open
- Do not reuse foreground shell sessions — stale sessions block future terminal operations in Codespaces
- In GitHub Codespaces, agent-spawned terminals may be hidden — they still work. Do not assume a terminal is broken if you cannot see it
- If a terminal appears unresponsive, kill it and create a new one rather than retrying in the same terminal'

usage() {
  echo "auto-kill-terminal v${VERSION}"
  echo ""
  echo "Usage: install.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --dry-run     Preview changes without modifying files"
  echo "  --force       Overwrite even if terminal rules already exist"
  echo "  --dir PATH    Target directory (default: current directory)"
  echo "  --all         Create all agent files (copilot, claude, gemini, agents)"
  echo "  --copilot     Create/update .github/copilot-instructions.md only"
  echo "  --claude      Create/update CLAUDE.md only"
  echo "  --gemini      Create/update GEMINI.md only"
  echo "  --cursor      Create/update .cursorrules only"
  echo "  --help        Show this help message"
  echo ""
  echo "With no flags, auto-detects existing agent files and appends rules."
}

log_info() { echo -e "${BLUE}[info]${NC} $1"; }
log_ok() { echo -e "${GREEN}[done]${NC} $1"; }
log_skip() { echo -e "${YELLOW}[skip]${NC} $1"; }
log_dry() { echo -e "${YELLOW}[dry-run]${NC} $1"; }
log_err() { echo -e "${RED}[error]${NC} $1"; }

has_terminal_rules() {
  local file="$1"
  grep -q "Always kill the terminal" "$file" 2>/dev/null
}

append_rules() {
  local file="$1"
  local label="$2"

  if [[ -f "$file" ]] && has_terminal_rules "$file" && [[ "$FORCE" != true ]]; then
    log_skip "$label — terminal rules already present"
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    if [[ -f "$file" ]]; then
      log_dry "Would append terminal rules to $label"
    else
      log_dry "Would create $label with terminal rules"
    fi
    return
  fi

  mkdir -p "$(dirname "$file")"

  if [[ -f "$file" ]]; then
    echo "" >> "$file"
    echo "$TERMINAL_RULES" >> "$file"
    log_ok "Appended terminal rules to $label"
  else
    echo "$TERMINAL_RULES" > "$file"
    log_ok "Created $label with terminal rules"
  fi
}

# Parse arguments
TARGETS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; shift ;;
    --dir) DIR="$2"; shift 2 ;;
    --all) TARGETS=("copilot" "claude" "gemini" "agents" "cursor"); shift ;;
    --copilot) TARGETS+=("copilot"); shift ;;
    --claude) TARGETS+=("claude"); shift ;;
    --gemini) TARGETS+=("gemini"); shift ;;
    --cursor) TARGETS+=("cursor"); shift ;;
    --help|-h) usage; exit 0 ;;
    *) log_err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

echo ""
echo -e "${GREEN}auto-kill-terminal${NC} v${VERSION}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$DIR"

# Auto-detect mode
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  log_info "Auto-detecting agent instruction files..."
  found=false

  if [[ -f ".github/copilot-instructions.md" ]]; then
    TARGETS+=("copilot"); found=true
  fi
  if [[ -f "CLAUDE.md" ]]; then
    TARGETS+=("claude"); found=true
  fi
  if [[ -f "GEMINI.md" ]]; then
    TARGETS+=("gemini"); found=true
  fi
  if [[ -f "AGENTS.md" ]]; then
    TARGETS+=("agents"); found=true
  fi
  if [[ -f ".cursorrules" ]]; then
    TARGETS+=("cursor"); found=true
  fi
  if [[ -f ".windsurfrules" ]]; then
    TARGETS+=("windsurf"); found=true
  fi
  if [[ -f ".clinerules" ]]; then
    TARGETS+=("cline"); found=true
  fi

  if [[ "$found" == false ]]; then
    log_info "No agent files found. Creating .github/copilot-instructions.md and CLAUDE.md"
    TARGETS=("copilot" "claude")
  fi
fi

# Apply
for target in "${TARGETS[@]}"; do
  case $target in
    copilot)  append_rules ".github/copilot-instructions.md" ".github/copilot-instructions.md" ;;
    claude)   append_rules "CLAUDE.md" "CLAUDE.md" ;;
    gemini)   append_rules "GEMINI.md" "GEMINI.md" ;;
    agents)   append_rules "AGENTS.md" "AGENTS.md" ;;
    cursor)   append_rules ".cursorrules" ".cursorrules" ;;
    windsurf) append_rules ".windsurfrules" ".windsurfrules" ;;
    cline)    append_rules ".clinerules" ".clinerules" ;;
  esac
done

echo ""
if [[ "$DRY_RUN" == true ]]; then
  echo -e "${YELLOW}Dry run complete. No files were modified.${NC}"
else
  echo -e "${GREEN}Done!${NC} Your AI agents will now clean up after themselves. 🧹"
fi
echo ""
