#!/usr/bin/env bash
# Decepticon MCP — Claude Code Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/sriram162003/decepticon-mcp/main/install.sh | bash

set -euo pipefail

REPO_URL="https://github.com/sriram162003/decepticon-mcp"
DECEPTICON_REPO="https://github.com/PurpleAILAB/Decepticon"
INSTALL_DIR="$HOME/decepticon-mcp"
DECEPTICON_DIR="$HOME/Decepticon"
CLAUDE_DIR="$HOME/.claude"
VENV_DIR="$DECEPTICON_DIR/.venv-mcp"
PYTHON_MIN="3.13"

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info()    { echo -e "${BOLD}${GREEN}[+]${RESET} $*"; }
warn()    { echo -e "${BOLD}${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${BOLD}${RED}[✗]${RESET} $*"; exit 1; }
success() { echo -e "${BOLD}${GREEN}[✓]${RESET} $*"; }

echo -e "\n${BOLD}Decepticon MCP — Claude Code Installer${RESET}\n"

# ── 1. Check dependencies ────────────────────────────────────────────────────
info "Checking dependencies..."
command -v git  >/dev/null 2>&1 || error "git is required. Install it and retry."
command -v uv   >/dev/null 2>&1 || error "uv is required. Install: curl -LsSf https://astral.sh/uv/install.sh | sh"
command -v jq   >/dev/null 2>&1 || error "jq is required. Install: brew install jq (macOS) or apt install jq (Linux)"

# ── 2. Clone / update this repo ──────────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
    info "Updating decepticon-mcp repo..."
    git -C "$INSTALL_DIR" pull --ff-only --quiet
else
    info "Cloning decepticon-mcp..."
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

# ── 3. Clone / update Decepticon source ─────────────────────────────────────
if [ -d "$DECEPTICON_DIR/.git" ]; then
    info "Decepticon repo already present at $DECEPTICON_DIR"
else
    info "Cloning PurpleAILAB/Decepticon..."
    git clone --depth 1 "$DECEPTICON_REPO" "$DECEPTICON_DIR"
fi

# ── 4. Create Python 3.13 venv and install packages ─────────────────────────
info "Setting up Python $PYTHON_MIN environment..."
if [ ! -f "$VENV_DIR/bin/python" ]; then
    uv venv --python "$PYTHON_MIN" "$VENV_DIR"
fi
info "Installing decepticon + mcp packages..."
uv pip install --python "$VENV_DIR/bin/python" \
    -e "$DECEPTICON_DIR/packages/decepticon" \
    mcp \
    --quiet
success "Python environment ready (73 tools)"

# ── 5. Copy MCP server ───────────────────────────────────────────────────────
info "Installing MCP server..."
cp "$INSTALL_DIR/mcp_server.py" "$DECEPTICON_DIR/mcp_server.py"

# ── 6. Install agents ────────────────────────────────────────────────────────
info "Installing Claude Code agents..."
mkdir -p "$CLAUDE_DIR/agents"
cp "$INSTALL_DIR/agents/"*.md "$CLAUDE_DIR/agents/"
success "Installed $(ls "$INSTALL_DIR/agents/"*.md | wc -l | tr -d ' ') agents"

# ── 7. Install skill ─────────────────────────────────────────────────────────
info "Installing /decepticon skill..."
mkdir -p "$CLAUDE_DIR/skills/decepticon"
cp "$INSTALL_DIR/skills/decepticon/SKILL.md" "$CLAUDE_DIR/skills/decepticon/SKILL.md"
success "Skill installed → /decepticon"

# ── 8. Register MCP server in Claude Code settings ──────────────────────────
info "Registering MCP server in ~/.claude/settings.json..."
SETTINGS="$CLAUDE_DIR/settings.json"
PYTHON_BIN="$VENV_DIR/bin/python"
MCP_SCRIPT="$DECEPTICON_DIR/mcp_server.py"

if [ ! -f "$SETTINGS" ]; then
    echo '{}' > "$SETTINGS"
fi

UPDATED=$(jq \
    --arg cmd "$PYTHON_BIN" \
    --arg script "$MCP_SCRIPT" \
    '.mcpServers.decepticon = {"command": $cmd, "args": [$script]}' \
    "$SETTINGS")
echo "$UPDATED" > "$SETTINGS"
success "MCP server registered"

# ── 9. Done ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}Installation complete!${RESET}"
echo ""
echo "  Restart Claude Code, then:"
echo "  • /decepticon     → start a red team engagement"
echo "  • /mcp            → verify 73 Decepticon tools are loaded"
echo ""
echo "  Agents installed:"
for f in "$INSTALL_DIR/agents/"*.md; do
    echo "    • $(basename "$f" .md)"
done
echo ""
