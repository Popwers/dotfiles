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
brew install curl wget bash git vim neovim oven-sh/bun/bun fish jandedobbeleer/oh-my-posh/oh-my-posh bat eza fd ripgrep ffmpeg scrcpy tw93/tap/mole

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
if ! grep -q $(which fish) /etc/shells; then
    echo $(which fish) | sudo tee -a /etc/shells
    chsh -s $(which fish)
    echo "Fish shell is now the default shell."
else
    echo "Fish shell is already the default shell."
fi

# Switch to fish shell and execute commands
fish <<EOF
source ~/.config/fish/config.fish

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
bun install -g eslint prettier ngrok npm-check-updates pm2 typescript commitizen cz-conventional-changelog nx@latest

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

# Install OpenCode plugins
bunx oh-my-opencode install --no-tui --claude=yes --chatgpt=no --gemini=no
bunx opencode-supermemory install --no-tui

# Copy OpenCode configuration files
mkdir -p ~/.config/opencode/command
cp "$SCRIPT_DIR/opencode/opencode.json" ~/.config/opencode/
cp "$SCRIPT_DIR/opencode/oh-my-opencode.json" ~/.config/opencode/
cp "$SCRIPT_DIR/opencode/AGENTS.md" ~/.config/opencode/
cp "$SCRIPT_DIR/opencode/command/supermemory-init.md" ~/.config/opencode/command/

# Setup brew
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Mac setup is complete!"
echo "Don't forget to set your terminal font to JetBrains Mono Nerd Font and Symbols Only"
echo "To configure Supermemory, create ~/.config/opencode/supermemory.jsonc with your API key:"
echo '  { "apiKey": "your_supermemory_api_key" }'
echo "Restart your terminal to apply changes"
