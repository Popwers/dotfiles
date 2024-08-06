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
