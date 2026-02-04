#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Install Homebrew
if test ! $(which brew); then
    echo "Installing Homebrew for you."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Update Homebrew
brew update && brew upgrade

# Install packages
brew install --formula curl wget bash git gh vim neovim oven-sh/bun/bun fish jandedobbeleer/oh-my-posh/oh-my-posh bat eza fd ripgrep ffmpeg scrcpy tw93/tap/mole ollama

# Start Ollama and pull default embeddings model
if command -v ollama >/dev/null 2>&1; then
    ollama serve >/tmp/ollama.log 2>&1 &
    ollama_pid=$!
    sleep 2
    ollama pull nomic-embed-text
    if kill -0 "$ollama_pid" 2>/dev/null; then
        kill "$ollama_pid"
        wait "$ollama_pid" 2>/dev/null
    fi
fi

# Install casks
brew install --cask android-platform-tools

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
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# Install plugins
fisher install jorgebucaran/nvm.fish
fisher install rstacruz/fish-npm-global

# Install NVM and use LTS version
nvm install lts
nvm use lts

# Install global packages
bun install -g ngrok npm-check-updates typescript commitizen cz-conventional-changelog agent-browser @openai/codex @playwright/test

# Add bun to path
fish_add_path ~/.bun/bin

# Update fish completions
fish_update_completions
EOF

# Cleanup
brew cleanup

# Copy configuration files from repo
cp "$SCRIPT_DIR/.profile" ~/.profile
cp "$SCRIPT_DIR/.czrc" ~/.czrc
cp "$SCRIPT_DIR/.gitconfig" ~/.gitconfig

mkdir -p ~/.config/fish
cp "$SCRIPT_DIR/config.fish" ~/.config/fish/config.fish

mkdir -p ~/.config/nvim
cp "$SCRIPT_DIR/init.vim" ~/.config/nvim/init.vim

# Install OpenCode via official installer (not brew - avoids node dependency conflict with nvm.fish)
curl -fsSL https://opencode.ai/install | bash

# Install grepai
curl -sSL https://raw.githubusercontent.com/yoanbernabeu/grepai/main/install.sh | sh

# Install OpenCode plugins
bunx opencode-supermemory@latest install --no-tui

# Copy OpenCode configuration directory (clean sync)
mkdir -p ~/.config/opencode
rsync -a --delete "$SCRIPT_DIR/opencode/" ~/.config/opencode/

# Copy OpenCode agent to Codex
mkdir -p ~/.codex
cp "$SCRIPT_DIR/opencode/AGENTS.md" ~/.codex/AGENTS.md

# Setup brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install skills
bunx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser -g -a opencode codex -y
bunx skills add https://github.com/vercel-labs/agent-skills --skill vercel-react-native-skills -g -a opencode codex -y
bunx skills add https://github.com/vercel-labs/agent-skills --skill vercel-react-best-practices -g -a opencode codex -y
bunx skills add https://github.com/vercel-labs/agent-skills --skill web-design-guidelines -g -a opencode codex -y
bunx skills add https://github.com/vercel-labs/skills --skill find-skills -g -a opencode codex -y
bunx skills add https://github.com/anthropics/skills --skill frontend-design -g -a opencode codex -y
bunx skills add coreyhaines31/marketingskills -g -a opencode codex -y
bunx skills add yoanbernabeu/grepai-skills -g -a opencode codex -y

agent-browser install  # Download Chromium

echo "Mac setup is complete!"
echo "Don't forget to set your terminal font to JetBrains Mono Nerd Font and Symbols Only"
echo "Restart your terminal to apply changes"
