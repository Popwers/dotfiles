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

#oh-my-posh font install

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
cat << EOF > ~/.profile
eval "\$(/opt/homebrew/bin/brew shellenv)"

export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm

export PATH="\$HOME/.node_modules/bin:\$PATH"
export npm_config_prefix="\$HOME/.node_modules"
EOF

# Create .config/fish/config.fish file
mkdir -p ~/.config/fish
cat << EOF > ~/.config/fish/config.fish
set fish_greeting ""
set -gx TERM xterm-256color

# Setup brew
eval "\$(/opt/homebrew/bin/brew shellenv)"

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
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path /usr/local/bin
fish_add_path bin
fish_add_path ~/bin
fish_add_path ~/.local/bin
fish_add_path node_modules/.bin

# NodeJS
set --universal nvm_default_version lts

#VSCODE AND CURSOR
if test "\$TERM_PROGRAM" = "vscode" -o "\$TERM_PROGRAM" = "cursor"
    . (code --locate-shell-integration-path fish)
end

oh-my-posh init fish --config (brew --prefix oh-my-posh)/themes/jandedobbeleer.omp.json | source
EOF

# Setup brew
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Mac setup is complete!"
echo "Don't forget to set your terminal font to JetBrains Mono Nerd Font and Symbols Only"
echo "Restart your terminal to apply changes"
