#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Copy a file with visible status messages.
copy_file_with_status() {
    local source_file=$1
    local destination_file=$2

    echo "Copying file: $source_file -> $destination_file"
    mkdir -p "$(dirname "$destination_file")"
    cp "$source_file" "$destination_file"
    echo "Copied file: $destination_file"
}

# Sync a directory with visible status messages.
sync_dir_with_status() {
    local source_dir=$1
    local destination_dir=$2

    echo "Syncing directory: $source_dir -> $destination_dir"
    mkdir -p "$destination_dir"
    rsync -a --delete "$source_dir/" "$destination_dir/"
    echo "Synced directory: $destination_dir"
}

# Install Homebrew
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew for you."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Update Homebrew
brew update && brew upgrade

# Install packages
brew install --formula curl wget bash git gh vim neovim oven-sh/bun/bun fish jandedobbeleer/oh-my-posh/oh-my-posh bat eza fd ripgrep ffmpeg scrcpy tw93/tap/mole

# Install Ollama only when missing
if command -v ollama >/dev/null 2>&1 || brew list --formula ollama >/dev/null 2>&1; then
    echo "Ollama is already installed."
else
    brew install ollama
fi

# Start Ollama and pull default embeddings model
if command -v ollama >/dev/null 2>&1; then
    ollama serve >/tmp/ollama.log 2>&1 &
    ollama_pid=$!
    sleep 2

    if ollama list 2>/dev/null | awk 'NR > 1 {print $1}' | grep -Eq '^nomic-embed-text(:|$)'; then
        echo "Ollama model 'nomic-embed-text' is already present."
    else
        ollama pull nomic-embed-text
    fi

    if kill -0 "$ollama_pid" 2>/dev/null; then
        kill "$ollama_pid"
        wait "$ollama_pid" 2>/dev/null
    fi
fi

# Install casks
if brew list --cask android-platform-tools >/dev/null 2>&1; then
    echo "Cask 'android-platform-tools' is already installed."
else
    brew install --cask android-platform-tools
fi

# Function to install fonts
install_font() {
    local font_name=$1
    local font_file=$2
    local cask_name=$3

    if [ -f "$HOME/Library/Fonts/$font_file" ]; then
        echo "$font_name is already installed."
    else
        echo "Installing $font_name for you."
        brew install --cask $cask_name
    fi
}

# Install fonts
install_font "JetBrains Mono" "JetBrainsMono-Regular.ttf" "font-jetbrains-mono-nerd-font"
install_font "Symbols Only" "SymbolsNerdFont-Regular.ttf" "font-symbols-only-nerd-font"

# Init fish shell as default shell
fish_path="$(command -v fish)"
if [ -n "$fish_path" ] && ! grep -q "$fish_path" /etc/shells; then
    echo "$fish_path" | sudo tee -a /etc/shells
    chsh -s "$fish_path"
    echo "Fish shell is now the default shell."
else
    echo "Fish shell is already the default shell."
fi

# Switch to fish shell and execute commands
fish <<EOF
if test -f "$SCRIPT_DIR/config.fish"
    source "$SCRIPT_DIR/config.fish"
end

fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path /usr/local/bin

# Add Fisher
if not command -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
else
    echo "Fisher is already installed."
end

# Install plugins
if fisher list | string match -q 'jorgebucaran/nvm.fish'
    echo "Fisher plugin 'jorgebucaran/nvm.fish' is already installed."
else
    fisher install jorgebucaran/nvm.fish
end

if fisher list | string match -q 'rstacruz/fish-npm-global'
    echo "Fisher plugin 'rstacruz/fish-npm-global' is already installed."
else
    fisher install rstacruz/fish-npm-global
end

# Install NVM and use LTS version
if command -q nvm
    if nvm ls lts 2>/dev/null | string match -rq 'v[0-9]+\.[0-9]+\.[0-9]+'; then
        echo "Node.js LTS is already installed in nvm."
    else
        nvm install lts
    end
    nvm use lts
else
    echo "nvm command not found after Fisher install; skipping Node.js LTS setup."
end

# Install global packages
set -l bun_global_listing (bun pm ls -g 2>/dev/null | string collect)
set -l missing_bun_globals
for pkg in ngrok npm-check-updates typescript commitizen cz-conventional-changelog agent-browser @openai/codex
    if string match -rq "(^|\\s)$pkg@" -- $bun_global_listing
        echo "Bun global package '$pkg' is already installed."
    else
        set missing_bun_globals $missing_bun_globals $pkg
    end
end

if test (count $missing_bun_globals) -gt 0
    bun install -g $missing_bun_globals
else
    echo "All Bun global packages are already installed."
end

# Add bun to path
fish_add_path ~/.bun/bin

# Update fish completions
fish_update_completions
EOF

# Cleanup
brew cleanup

# Copy configuration files from repo
copy_file_with_status "$SCRIPT_DIR/.profile" "$HOME/.profile"
copy_file_with_status "$SCRIPT_DIR/.czrc" "$HOME/.czrc"
copy_file_with_status "$SCRIPT_DIR/.gitconfig" "$HOME/.gitconfig"
copy_file_with_status "$SCRIPT_DIR/config.fish" "$HOME/.config/fish/config.fish"
copy_file_with_status "$SCRIPT_DIR/init.vim" "$HOME/.config/nvim/init.vim"

# Install OpenCode via official installer (not brew - avoids node dependency conflict with nvm.fish)
if [ -x "$HOME/.opencode/bin/opencode" ] || command -v opencode >/dev/null 2>&1; then
    echo "OpenCode is already installed."
else
    curl -fsSL https://opencode.ai/install | bash
fi

# Install grepai
if command -v grepai >/dev/null 2>&1; then
    echo "GrepAI is already installed."
else
    curl -sSL https://raw.githubusercontent.com/yoanbernabeu/grepai/main/install.sh | sh
fi

# Install OpenCode plugins
if [ -f "$HOME/.config/opencode/supermemory.jsonc" ] && [ -f "$HOME/.config/opencode/opencode.json" ]; then
    echo "OpenCode supermemory plugin appears to be already configured."
else
    bunx opencode-supermemory@latest install --no-tui
fi

# Copy OpenCode configuration directory (clean sync)
sync_dir_with_status "$SCRIPT_DIR/opencode" "$HOME/.config/opencode"

# Copy OpenCode agent and Codex subagents
copy_file_with_status "$SCRIPT_DIR/opencode/AGENTS.md" "$HOME/.codex/AGENTS.md"
sync_dir_with_status "$SCRIPT_DIR/codex/agents" "$HOME/.codex/agents"

# Copy Codex configuration
copy_file_with_status "$SCRIPT_DIR/codex/config.toml" "$HOME/.codex/config.toml"

# Setup brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Check if a skill is already available for Codex/OpenCode.
is_skill_installed() {
    local skill_name=$1

    [ -d "$HOME/.agents/skills/$skill_name" ] ||
        [ -e "$HOME/.codex/skills/$skill_name" ] ||
        [ -e "$HOME/.config/opencode/skills/$skill_name" ]
}

# Install a skill only when missing.
install_skill_if_missing() {
    local skill_name=$1
    local skill_source=$2
    shift 2

    if is_skill_installed "$skill_name"; then
        echo "Skill '$skill_name' is already installed."
        return 0
    fi

    echo "Installing skill '$skill_name'..."
    bunx --bun skills add "$skill_source" "$@" -g -a opencode codex -y
}

are_all_skills_installed() {
    local skill_name
    for skill_name in "$@"; do
        if ! is_skill_installed "$skill_name"; then
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
        echo "Skill bundle '$skill_source' is already installed."
        return 0
    fi

    echo "Installing skill bundle '$skill_source'..."
    bunx --bun skills add "$skill_source" -g -a opencode codex -y
}

# Install skills
install_skill_if_missing "agent-browser" "https://github.com/vercel-labs/agent-browser" --skill agent-browser
install_skill_if_missing "vercel-react-native-skills" "https://github.com/vercel-labs/agent-skills" --skill vercel-react-native-skills
install_skill_if_missing "vercel-react-best-practices" "https://github.com/vercel-labs/agent-skills" --skill vercel-react-best-practices
install_skill_if_missing "vercel-composition-patterns" "https://github.com/vercel-labs/agent-skills" --skill vercel-composition-patterns
install_skill_if_missing "web-design-guidelines" "https://github.com/vercel-labs/agent-skills" --skill web-design-guidelines
install_skill_if_missing "find-skills" "https://github.com/vercel-labs/skills" --skill find-skills
install_skill_if_missing "frontend-design" "https://github.com/anthropics/skills" --skill frontend-design
install_skill_if_missing "doc-coauthoring" "https://github.com/anthropics/skills" --skill doc-coauthoring
install_skill_if_missing "webapp-testing" "https://github.com/anthropics/skills" --skill webapp-testing
install_skill_if_missing "playwright" "https://github.com/openai/skills" --skill playwright
install_skill_if_missing "yeet" "https://github.com/openai/skills" --skill yeet
install_skill_bundle_if_missing "better-auth/skills" "better-auth-best-practices" "organization-best-practices" "two-factor-authentication-best-practices"
install_skill_bundle_if_missing "coreyhaines31/marketingskills" "marketing-ideas" "copywriting" "seo-audit"
install_skill_bundle_if_missing "yoanbernabeu/grepai-skills" "grepai-init" "grepai-search-basics" "grepai-troubleshooting"
install_skill_bundle_if_missing "shadcn/ui" "shadcn"
install_skill_if_missing "interface-feel-polish" "https://github.com/Popwers/skills" --skill interface-feel-polish

# Configure agent-browser right after install (downloads Chromium)
if [ -x "$HOME/.bun/bin/agent-browser" ]; then
    if compgen -G "$HOME/Library/Caches/ms-playwright/chromium-*" >/dev/null || compgen -G "$HOME/.cache/ms-playwright/chromium-*" >/dev/null; then
        echo "agent-browser Chromium dependency is already installed."
    else
        "$HOME/.bun/bin/agent-browser" install
    fi
    "$HOME/.bun/bin/agent-browser" --version
else
    echo "agent-browser binary not found in ~/.bun/bin"
fi

echo "Mac setup is complete!"
echo "Don't forget to set your terminal font to JetBrains Mono Nerd Font and Symbols Only"
echo "Restart your terminal to apply changes"
