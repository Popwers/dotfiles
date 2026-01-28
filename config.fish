if status is-interactive
    printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "fish"}}\x9c'
end

set fish_greeting ""
set -gx TERM xterm-256color
set -gx OPENCODE_EXPERIMENTAL true

# Setup brew (macOS only)
if test -x /opt/homebrew/bin/brew
    eval "(/opt/homebrew/bin/brew shellenv)"
end

# aliases
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."
alias grep "grep --color=auto"
alias mkdir "mkdir -p"
if type -q eza
    alias ls "eza --long --color=always --icons=always --all"
    alias l "eza --long --color=always --icons=always --all"
    alias lss "eza --long --color=always --icons=always --all --total-size --sort=size"
end

if type -q bat
    alias cat bat
end
alias vim nvim
alias vi nvim
alias cz "git cz"
alias ga "git add . && git cz"
if type -q brew
    alias upsys "brew update && brew upgrade && brew cleanup && brew doctor && bun upgrade && bun -g update"
end

function opencode
    set -l state_dir /tmp/opencode-state
    set -l lock_dir $state_dir/lock
    set -l count_file $state_dir/count
    set -l ollama_pid_file $state_dir/ollama.pid
    set -l manage_ollama_file $state_dir/ollama.manage
    set -l manage_grepai_file $state_dir/grepai.manage

    command mkdir -p $state_dir

    while not command mkdir $lock_dir 2>/dev/null
        sleep 0.05
    end

    set -l count 0
    if test -f $count_file
        set count (command cat $count_file)
    end
    set count (math $count + 1)
    echo $count > $count_file

    if test $count -eq 1
        if not set -q OPENCODE_KEEP_OLLAMA
            command touch $manage_ollama_file
            if command -v ollama >/dev/null 2>&1
                if not pgrep -f "ollama serve" >/dev/null 2>&1
                    nohup ollama serve >/tmp/ollama.log 2>&1 &
                    echo $last_pid > $ollama_pid_file
                    sleep 2
                end
            end
        end

        if test -f .grepai/config.yaml
            if not set -q OPENCODE_KEEP_GREPAI
                command touch $manage_grepai_file
                if not pgrep -f "grepai watch" >/dev/null 2>&1
                    grepai watch --background
                end
            end
        end
    end

    command rmdir $lock_dir

    command opencode $argv

    while not command mkdir $lock_dir 2>/dev/null
        sleep 0.05
    end

    set -l count 1
    if test -f $count_file
        set count (command cat $count_file)
    end
    set count (math $count - 1)
    if test $count -le 0
        command rm -f $count_file
    else
        echo $count > $count_file
    end

    if test $count -le 0
        if test -f $manage_grepai_file
            if test -f .grepai/config.yaml
                grepai watch --stop
            end
            if pgrep -f "grepai watch" >/dev/null 2>&1
                pkill -f "grepai watch"
            end
            command rm -f $manage_grepai_file
        end

        if test -f $manage_ollama_file
            if test -f $ollama_pid_file
                set -l ollama_pid (command cat $ollama_pid_file)
                if test -n "$ollama_pid"
                    if kill -0 $ollama_pid 2>/dev/null
                        kill $ollama_pid
                        wait $ollama_pid 2>/dev/null
                    end
                end
                command rm -f $ollama_pid_file
            else
                if pgrep -f "ollama serve" >/dev/null 2>&1
                    pkill -f "ollama serve"
                end
            end
            command rm -f $manage_ollama_file
        end
    end

    command rmdir $lock_dir
end

# Path
if test -d /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end
if test -d /opt/homebrew/sbin
    fish_add_path /opt/homebrew/sbin
end
fish_add_path /usr/local/bin
fish_add_path bin
fish_add_path ~/bin
fish_add_path ~/.local/bin
fish_add_path ~/.orbstack/bin
fish_add_path ~/.opencode/bin
fish_add_path ~/.bun/bin
fish_add_path node_modules/.bin

# NodeJS
set --universal nvm_default_version lts

#VSCODE AND CURSOR
if test "$TERM_PROGRAM" = "vscode" -o "$TERM_PROGRAM" = "cursor"
    . (code --locate-shell-integration-path fish)
end

if test -f ~/.config/oh-my-posh/jandedobbeleer.omp.json
    oh-my-posh init fish --config ~/.config/oh-my-posh/jandedobbeleer.omp.json | source
end
