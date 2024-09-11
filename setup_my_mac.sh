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
if status is-interactive
    printf '\eP\$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "fish"}}\x9c'
end

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
alias cz "git cz"
alias upsys "brew update && brew upgrade && brew cleanup && brew doctor && bun upgrade && bun -g update"

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

# Create .czrc file
cat << EOF > ~/.czrc
{
    "path": "cz-conventional-changelog"
}
EOF

# Create init.vim file
cat << EOF > ~/.config/nvim/init.vim
" Search recursively downward from CWD; provides TAB completion for filenames
" e.g., \`:find vim* <TAB>\`
set path+=**

" number of lines at the beginning and end of files checked for file-specific vars
set modelines=0

" reload files changed outside of Vim not currently modified in Vim (needs below)
set autoread

" use Unicode
set encoding=utf-8

" don't create \`filename~\` backups
set nobackup

" don't create temp files
set noswapfile

" line numbers and distances
set relativenumber
set number

" Indent new line the same as the preceding line
set autoindent

" statusline indicates insert or normal mode
set showmode showcmd

" make scrolling and painting fast
" ttyfast kept for vim compatibility but not needed for nvim
set ttyfast lazyredraw

" highlight matching parens, braces, brackets, etc
set showmatch

" http://vim.wikia.com/wiki/Searching
set hlsearch incsearch ignorecase smartcase

" http://vim.wikia.com/wiki/Set_working_directory_to_the_current_file
set autochdir

" StatusLine always visible, display full path
" http://learnvimscriptthehardway.stevelosh.com/chapters/17.html
set laststatus=2 statusline=%F

" Use system clipboard
" for macOS
set clipboard=unnamed

" Folding
" https://vim.fandom.com/wiki/Folding
" https://vim.fandom.com/wiki/All_folds_open_when_opening_a_file
" https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
set foldmethod=indent
set foldnestmax=1
set foldlevelstart=1

" Neovim only
set termguicolors

" Enable mouse support
set mouse=a

" Set background to transparent
highlight Normal guibg=NONE ctermbg=NONE
highlight NonText guibg=NONE ctermbg=NONE
EOF

# Setup brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Setup git
git config --global user.name "Popwers"
git config --global user.email "lionel.bataille@hotmail.com"
git config --global core.editor "nvim"
git config --global init.defaultBranch "master"

echo "Mac setup is complete!"
echo "Don't forget to set your terminal font to JetBrains Mono Nerd Font and Symbols Only"
echo "Restart your terminal to apply changes"
