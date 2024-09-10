if status is-interactive
    printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "fish"}}\x9c'
end

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
if test "$TERM_PROGRAM" = "vscode" -o "$TERM_PROGRAM" = "cursor"
    . (code --locate-shell-integration-path fish)
end

oh-my-posh init fish --config (brew --prefix oh-my-posh)/themes/jandedobbeleer.omp.json | source
