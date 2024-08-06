#!/bin/bash

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
brew install curl wget bash git vim neovim oven-sh/bun/bun fish jandedobbeleer/oh-my-posh/oh-my-posh bat eza

# Install JetBrains Mono Nerdfont and Icon Font
# Check if font is already installed
if [ -d "~/Library/Fonts/JetBrainsMono-Regular.ttf" ]; then
  echo "JetBrains Mono is already installed."
else
  echo "Installing JetBrains Mono for you."
  brew install --cask font-jetbrains-mono-nerd-font
fi

# Check if font is already installed
if [ -d "~/Library/Fonts/SymbolsOnly.ttf" ]; then
  echo "Symbols Only is already installed."
else
  echo "Installing Symbols Only for you."
  brew install --cask font-symbols-only-nerd-font
fi

oh-my-posh font install

# Init fish shell as default shell
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)

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

# Add paths to fish config
fish_add_path "/Users/lionel/.bun/bin"

# Update fish completions
fish_update_completions
EOF

# Cleanup
brew cleanup

# Create .profile file
touch ~/.profile
echo '
eval "$(/opt/homebrew/bin/brew shellenv)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

export PATH="$HOME/.node_modules/bin:$PATH"
export npm_config_prefix="~/.node_modules"
' > ~/.profile

# Create .config/fish/config.fish file
mkdir -p ~/.config/fish
touch ~/.config/fish/config.fish
echo '
set fish_greeting ""
set -gx TERM xterm-256color

# Setup brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# aliases
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."
alias grep "grep --color=auto"
alias mkdir "mkdir -p"
alias ls "eza --long --color=always --icons=always --all"
alias l "eza --long --color=always --icons=always --all"
alias cat bat
alias vim nvim
alias vi nvim
alias upsys "brew update && brew upgrade && brew cleanup && brew doctor && bun -g update"

# Path
set -gx PATH /opt/homebrew/bin $PATH
set -gx PATH /opt/homebrew/sbin $PATH
set -gx PATH /usr/local/bin $PATH

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

# NodeJS
set -gx PATH node_modules/.bin $PATH
set --universal nvm_default_version lts

#VSCODE
string match -q "$TERM_PROGRAM" "vscode"
and . (code --locate-shell-integration-path fish)

oh-my-posh init fish --config $(brew --prefix oh-my-posh)/themes/jandedobbeleer.omp.json | source

' > ~/.config/fish/config.fish

# Setup brew
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Mac setup is complete!"
