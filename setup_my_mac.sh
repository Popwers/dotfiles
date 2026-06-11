#!/bin/bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colored output helpers.
ok()      { printf '  \033[32m✓\033[0m %s\n' "$1"; }
skip()    { printf '  \033[90m– %s\033[0m\n' "$1"; }
warn()    { printf '  \033[33m! %s\033[0m\n' "$1"; }
section() { printf '\n\033[1;34m==> %s\033[0m\n\n' "$1"; }

# Copy a file and confirm.
copy_file_with_status() {
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
    ok "$2"
}

# Sync a directory and confirm.
sync_dir_with_status() {
    mkdir -p "$2"
    rsync -a --delete "$1/" "$2/"
    ok "$2"
}

section "Homebrew"

# Install Homebrew
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew for you."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { echo "Homebrew install failed"; exit 1; }
else
    skip "Homebrew"
fi

# Update Homebrew
brew update && brew upgrade

# Install formulas (only missing ones to avoid noise)
brew_formulas=(curl wget bash git gh vim neovim oven-sh/bun/bun fish jandedobbeleer/oh-my-posh/oh-my-posh bat eza fd ripgrep ffmpeg scrcpy tw93/tap/mole rtk uv)
installed_formulas=$(brew list --formula -1 2>/dev/null)
missing_formulas=()
for f in "${brew_formulas[@]}"; do
    pkg="${f##*/}"
    if ! echo "$installed_formulas" | grep -qx "$pkg"; then
        missing_formulas+=("$f")
    fi
done
if [ ${#missing_formulas[@]} -gt 0 ]; then
    echo "Installing missing formulas: ${missing_formulas[*]}"
    brew install --formula "${missing_formulas[@]}"
else
    skip "All formulas up to date"
fi

section "Ollama"

# The Homebrew formula ships Ollama without the llama-server runner (embeddings fail with HTTP 500).
# Use the official app cask instead, and migrate away from the broken formula if present.
if brew list --formula ollama >/dev/null 2>&1; then
    brew uninstall --formula ollama
fi
if brew list --cask ollama-app >/dev/null 2>&1; then
    skip "Ollama"
else
    brew install --cask ollama-app
fi

# Start Ollama (if not already running) and pull default embeddings model
if command -v ollama >/dev/null 2>&1; then
    ollama_started_here=false
    if ! ollama list &>/dev/null; then
        ollama serve >/tmp/ollama.log 2>&1 &
        ollama_pid=$!
        ollama_started_here=true
        for _ in $(seq 1 20); do
            ollama list &>/dev/null && break
            sleep 0.5
        done
    fi

    if ollama list 2>/dev/null | awk 'NR > 1 {print $1}' | grep -Eq '^nomic-embed-text(:|$)'; then
        skip "Model nomic-embed-text"
    else
        ollama pull nomic-embed-text
    fi

    if [ "$ollama_started_here" = true ] && kill -0 "$ollama_pid" 2>/dev/null; then
        kill "$ollama_pid"
        wait "$ollama_pid" 2>/dev/null
    fi
fi

section "Casks & Fonts"

# Install casks
if brew list --cask android-platform-tools >/dev/null 2>&1; then
    skip "android-platform-tools"
else
    brew install --cask android-platform-tools
fi

# Function to install fonts
install_font() {
    local font_name=$1
    local font_file=$2
    local cask_name=$3

    if [ -f "$HOME/Library/Fonts/$font_file" ]; then
        skip "$font_name"
    else
        brew install --cask $cask_name
        ok "$font_name"
    fi
}

# Install fonts
install_font "JetBrains Mono" "JetBrainsMono-Regular.ttf" "font-jetbrains-mono-nerd-font"
install_font "Symbols Only" "SymbolsNerdFont-Regular.ttf" "font-symbols-only-nerd-font"

section "Fish Shell"

# Init fish shell as default shell
fish_path="$(command -v fish)"
if [ -n "$fish_path" ]; then
    if ! grep -q "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells
    fi
    if [ "$SHELL" = "$fish_path" ]; then
        skip "Fish default shell"
    else
        if chsh -s "$fish_path" 2>/dev/null; then
            ok "Fish default shell"
        else
            warn "Run manually: chsh -s $fish_path"
        fi
    fi
fi

# Switch to fish shell and execute commands
SCRIPT_DIR_EXPORT="$SCRIPT_DIR" fish <<'FISH'
function ok;   printf '  \033[32m✓\033[0m %s\n' "$argv"; end
function skip; printf '  \033[90m– %s\033[0m\n' "$argv"; end
function warn; printf '  \033[33m! %s\033[0m\n' "$argv"; end

if test -f "$SCRIPT_DIR_EXPORT/config.fish"
    source "$SCRIPT_DIR_EXPORT/config.fish"
end

fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path /usr/local/bin

# Add Fisher (type -q detects fish functions, command -q only finds binaries)
if not type -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
else
    skip "Fisher"
end

# Remove obsolete nvm.fish plugin — Node is now managed by Vite+ (`vp env`).
if fisher list 2>/dev/null | string match -q 'jorgebucaran/nvm.fish'
    fisher remove jorgebucaran/nvm.fish
    ok "Removed legacy nvm.fish plugin"
end

# Install global packages
set -l bun_global_listing (bun pm ls -g 2>/dev/null | string collect)
set -l missing_bun_globals
for pkg in ngrok npm-check-updates commitizen cz-conventional-changelog @openai/codex impeccable
    if string match -rq "(^|\\s)$pkg@" -- $bun_global_listing
        skip "$pkg"
    else
        set missing_bun_globals $missing_bun_globals $pkg
    end
end

if test (count $missing_bun_globals) -gt 0
    bun install -g $missing_bun_globals
else
    skip "All bun globals up to date"
end


# Add bun to path
fish_add_path ~/.bun/bin

# Update fish completions (skip if refreshed within 24h)
set -l comp_marker "$HOME/.cache/fish/.completions_updated"
if test -f "$comp_marker"; and test (math (date +%s) - (stat -f %m "$comp_marker")) -lt 86400
    skip "Fish completions (< 24h)"
else
    fish_update_completions
    mkdir -p "$HOME/.cache/fish"
    touch "$comp_marker"
end
FISH

section "Vite+"

# Install Vite+ (managed Node.js + unified Vite/Vitest/Oxlint/Oxfmt/tsgo toolchain).
# VP_NODE_MANAGER=yes skips the interactive prompt so the script stays idempotent.
if [ -x "$HOME/.vite-plus/bin/vp" ]; then
    skip "Vite+"
else
    VP_NODE_MANAGER=yes curl -fsSL https://vite.plus | bash
fi

# Make sure the user-level Fish conf.d snippet exists so `vp` is on PATH next shell.
if [ -f "$HOME/.vite-plus/env.fish" ] && [ ! -f "$HOME/.config/fish/conf.d/vite-plus.fish" ]; then
    mkdir -p "$HOME/.config/fish/conf.d"
    {
        echo "# Added by setup_my_mac.sh — load Vite+ environment for interactive shells."
        echo "source \$HOME/.vite-plus/env.fish"
    } > "$HOME/.config/fish/conf.d/vite-plus.fish"
    ok "Vite+ Fish integration"
fi

section "Claude Code"

# Install Claude Code via official installer
if command -v claude >/dev/null 2>&1; then
    skip "Claude Code"
else
    curl -fsSL https://claude.ai/install.sh | bash
fi

section "Configuration"

# Copy configuration files from repo
copy_file_with_status "$SCRIPT_DIR/.profile" "$HOME/.profile"
copy_file_with_status "$SCRIPT_DIR/.czrc" "$HOME/.czrc"
copy_file_with_status "$SCRIPT_DIR/.gitconfig" "$HOME/.gitconfig"
copy_file_with_status "$SCRIPT_DIR/config.fish" "$HOME/.config/fish/config.fish"
copy_file_with_status "$SCRIPT_DIR/init.vim" "$HOME/.config/nvim/init.vim"

# Install grepai
if command -v grepai >/dev/null 2>&1; then
    skip "GrepAI"
else
    curl -sSL https://raw.githubusercontent.com/yoanbernabeu/grepai/main/install.sh | sh
fi

# uv installs CLI tools into ~/.local/bin — make sure it's reachable for the rest of the script.
export PATH="$HOME/.local/bin:$PATH"

# Install Serena (LSP-based symbolic code navigation MCP — https://github.com/oraios/serena)
if command -v serena >/dev/null 2>&1; then
    skip "Serena"
else
    uv tool install -p 3.13 serena-agent
    serena init
    ok "Serena"
fi

# The Serena web dashboard is unused — disable it entirely (no local server, no browser tab on launch).
SERENA_CONFIG="$HOME/.serena/serena_config.yml"
if [ -f "$SERENA_CONFIG" ] && grep -qE "^(web_dashboard|web_dashboard_open_on_launch): true" "$SERENA_CONFIG"; then
    sed -i '' -e 's/^web_dashboard: true/web_dashboard: false/' \
        -e 's/^web_dashboard_open_on_launch: true/web_dashboard_open_on_launch: false/' "$SERENA_CONFIG"
    ok "Serena dashboard disabled"
fi

# Install Graphify CLI (one-shot knowledge-graph maps — https://github.com/safishamsi/graphify)
# PyPI package is temporarily named graphifyy; the CLI and skill are still `graphify`.
if command -v graphify >/dev/null 2>&1; then
    skip "Graphify"
else
    uv tool install graphifyy
    ok "Graphify"
fi

# Copy Codex configuration
copy_file_with_status "$SCRIPT_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
copy_file_with_status "$SCRIPT_DIR/codex/config.toml" "$HOME/.codex/config.toml"
copy_file_with_status "$SCRIPT_DIR/codex/hooks.json" "$HOME/.codex/hooks.json"
sync_dir_with_status "$SCRIPT_DIR/codex/agents" "$HOME/.codex/agents"
sync_dir_with_status "$SCRIPT_DIR/codex/hooks" "$HOME/.codex/hooks"

# Copy Claude Code configuration
copy_file_with_status "$SCRIPT_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
copy_file_with_status "$SCRIPT_DIR/claude/settings.json" "$HOME/.claude/settings.json"
copy_file_with_status "$SCRIPT_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
copy_file_with_status "$SCRIPT_DIR/claude/claudeignore.template" "$HOME/.claude/claudeignore.template"
chmod +x "$HOME/.claude/statusline.sh"
# Merge user preferences into ~/.claude.json (preserves existing state like stats/sessions)
if command -v jq &>/dev/null; then
    if [[ -f "$HOME/.claude.json" ]]; then
        jq -s '.[0] * .[1]' "$HOME/.claude.json" "$SCRIPT_DIR/claude/defaults.json" > /tmp/claude-merged.json \
            && mv /tmp/claude-merged.json "$HOME/.claude.json" \
            && ok "claude.json (merged)"
    else
        cp "$SCRIPT_DIR/claude/defaults.json" "$HOME/.claude.json"
        ok "claude.json (created)"
    fi
else
    warn "jq not found, skipping claude.json merge"
fi
# Register local MCP servers (user scope) — only if not already registered
if command -v claude &>/dev/null; then
    registered_mcps=$(claude mcp list --scope user 2>/dev/null || true)
    register_mcp_if_missing() {
        local name=$1; shift
        if echo "$registered_mcps" | grep -q "$name"; then
            skip "MCP $name"
        else
            if claude mcp add "$@" >/dev/null 2>&1; then
                ok "MCP $name"
            else
                warn "MCP $name registration failed — run manually: claude mcp add $*"
            fi
        fi
    }
    register_mcp_if_missing "context7" --transport http --scope user context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY:ctx7sk-1c3efdc8-aec6-417e-9cca-e36ed9696664"
    register_mcp_if_missing "gh_grep" --transport http --scope user gh_grep https://mcp.grep.app
    # Serena — official Claude Code global setup (per-workspace project via --project-from-cwd)
    if command -v serena >/dev/null 2>&1; then
        register_mcp_if_missing "serena" --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd
    else
        warn "serena CLI not found, skipping Serena MCP registration"
    fi
    # register_mcp_if_missing "exa" --transport http --scope user exa https://mcp.exa.ai --header "x-api-key:469853ea-7c4e-499e-8113-621615e8ebd2"
    unset -f register_mcp_if_missing
else
    warn "claude CLI not found, skipping MCP registration"
fi
sync_dir_with_status "$SCRIPT_DIR/claude/agents" "$HOME/.claude/agents"
sync_dir_with_status "$SCRIPT_DIR/claude/hooks" "$HOME/.claude/hooks"
sync_dir_with_status "$SCRIPT_DIR/claude/rules" "$HOME/.claude/rules"
sync_dir_with_status "$SCRIPT_DIR/claude/commands" "$HOME/.claude/commands"

# Install the Graphify skill (/graphify) — manages itself under ~/.claude/skills/graphify
if [ -e "$HOME/.claude/skills/graphify" ]; then
    skip "Graphify skill"
elif command -v graphify >/dev/null 2>&1; then
    graphify install && ok "Graphify skill"
else
    warn "graphify CLI not found, skipping Graphify skill install"
fi

# Ensure bun globals are on PATH for fresh bootstraps
export PATH="$HOME/.bun/bin:$PATH"

# Setup brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Check if a skill is already available for Codex and Claude Code.
skill_agent_dir() {
    local agent_name=$1

    case "$agent_name" in
        codex)
            printf '%s\n' "$HOME/.codex/skills"
            ;;
        claude-code)
            printf '%s\n' "$HOME/.claude/skills"
            ;;
        *)
            return 1
            ;;
    esac
}

is_skill_installed_for_agent() {
    local skill_name=$1
    local agent_name=$2
    local agent_dir

    agent_dir=$(skill_agent_dir "$agent_name") || return 1
    [ -e "$agent_dir/$skill_name" ]
}

is_skill_installed_everywhere() {
    local skill_name=$1
    local agent_name

    for agent_name in codex claude-code; do
        if ! is_skill_installed_for_agent "$skill_name" "$agent_name"; then
            return 1
        fi
    done

    return 0
}

# Create missing symlinks in agent skill dirs pointing to ~/.agents/skills/<name>.
ensure_skill_symlinks() {
    local skill_name=$1
    local global_dir="$HOME/.agents/skills/$skill_name"
    [ -d "$global_dir" ] || return 0

    local agent_name agent_dir
    for agent_name in codex claude-code; do
        agent_dir=$(skill_agent_dir "$agent_name") || continue
        if [ ! -e "$agent_dir/$skill_name" ]; then
            mkdir -p "$agent_dir"
            ln -s "$global_dir" "$agent_dir/$skill_name"
        fi
    done
}

# Install a skill only when missing.
install_skill_if_missing() {
    local skill_name=$1
    local skill_source=$2
    shift 2

    if is_skill_installed_everywhere "$skill_name"; then
        skip "$skill_name"
        return 0
    fi

    echo "  Installing $skill_name..."
    bunx --bun skills add "$skill_source" "$@" -g -a claude-code codex -y
    ensure_skill_symlinks "$skill_name"
}

are_all_skills_installed() {
    local skill_name
    for skill_name in "$@"; do
        if ! is_skill_installed_everywhere "$skill_name"; then
            return 1
        fi
    done

    return 0
}

install_skill_bundle_if_missing() {
    local skill_source=$1
    shift
    local required_skills=("$@")

    if are_all_skills_installed "${required_skills[@]}"; then
        skip "Bundle $skill_source"
        return 0
    fi

    echo "  Installing bundle $skill_source..."
    bunx --bun skills add "$skill_source" -g -a claude-code codex -y
    local skill_name
    for skill_name in "${required_skills[@]}"; do
        ensure_skill_symlinks "$skill_name"
    done
}

section "Skills"

# Sync all existing skills as symlinks for every agent before checking.
# The skills CLI only creates symlinks for claude-code; codex needs them
# too so the idempotency check passes.
if [ -d "$HOME/.agents/skills" ]; then
    for _skill_dir in "$HOME/.agents/skills"/*/; do
        ensure_skill_symlinks "$(basename "$_skill_dir")"
    done
    unset _skill_dir
fi

# Install skills — declarative table: "name|source"
declare -a skills=(
    "web-design-guidelines|https://github.com/vercel-labs/agent-skills"
    "impeccable|https://github.com/pbakaus/impeccable"
    "vercel-react-best-practices|https://github.com/vercel-labs/agent-skills"
    "vercel-composition-patterns|https://github.com/vercel-labs/agent-skills"
    "find-skills|https://github.com/vercel-labs/skills"
    "doc-coauthoring|https://github.com/anthropics/skills"
    "webapp-testing|https://github.com/anthropics/skills"
    "yeet|https://github.com/openai/skills"
    "copywriting|https://github.com/coreyhaines31/marketingskills"
    "seo-audit|https://github.com/coreyhaines31/marketingskills"
    "page-cro|https://github.com/coreyhaines31/marketingskills"
    "content-strategy|https://github.com/coreyhaines31/marketingskills"
    "site-architecture|https://github.com/coreyhaines31/marketingskills"
    "interface-feel-polish|https://github.com/Popwers/skills"
    "mcp-builder|https://github.com/anthropics/skills"
    "pdf|https://github.com/anthropics/skills"
    "docx|https://github.com/anthropics/skills"
    "xlsx|https://github.com/anthropics/skills"
    "pptx|https://github.com/anthropics/skills"
)

for entry in "${skills[@]}"; do
    IFS='|' read -r name source <<< "$entry"
    install_skill_if_missing "$name" "$source" --skill "$name"
done

install_skill_bundle_if_missing "shadcn/ui" "shadcn"

# Prune skills dropped from the loadout (redundant with CLAUDE.md policy, hooks, or other skills).
# Keeps re-runs and fresh machines consistent with the curated set.
declare -a pruned_skills=(
    "agent-browser"
    "playwright"
    "grepai-init"
    "grepai-mcp-claude"
    "grepai-search-basics"
    "grepai-search-tips"
    "grepai-trace-callees"
    "grepai-trace-callers"
    "grepai-watch-daemon"
    "grepai-workspaces"
)

prunable=""
for skill_name in "${pruned_skills[@]}"; do
    if [ -e "$HOME/.agents/skills/$skill_name" ]; then
        prunable="$prunable $skill_name"
    fi
done

if [ -n "$prunable" ]; then
    echo "  Pruning:$prunable..."
    # shellcheck disable=SC2086 — intentional word splitting on skill names
    bunx --bun skills remove $prunable -g -y
    ok "Pruned skills"
else
    skip "Pruned skills (none present)"
fi

# Activate the design-engineering skill for frontend work.
if is_skill_installed_everywhere "emil-design-engineering"; then
    skip "emil-design-engineering"
else
    curl -s "https://animations.dev/api/activate-design-engineering?email=lionel.bataille%40hotmail.com" | bash
fi
section "Finalization"

# Initialize RTK hooks for all agents (runs last so it can patch copied configs)
if command -v rtk >/dev/null 2>&1; then
    rtk init -g
    rtk init -g --auto-patch
    rtk init -g --codex
    rtk init -g --agent cursor
fi

printf '\n\033[1;32m  Mac setup is complete!\033[0m\n'
echo "  Set your terminal font to JetBrains Mono Nerd Font + Symbols Only"
echo "  Restart your terminal to apply changes"
