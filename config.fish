if status is-interactive
    printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "fish"}}\x9c'
end

set fish_greeting ""
set -gx OPENCODE_EXPERIMENTAL true

# aliases
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."
alias grep "rg"
alias mkdir "mkdir -p"
alias ls "eza --long --color=always --icons=always --all"
alias l "eza --long --color=always --icons=always --all"
alias lss "eza --long --color=always --icons=always --all --total-size --sort=size"
alias cat bat
alias vim nvim
alias vi nvim
alias cz "git cz"
alias ga "git add . && git cz"
alias upsys "brew update && brew upgrade && brew cleanup && brew doctor && bun upgrade && bun -g update && vp env install lts"

# Idempotent release helper for the opencode wrapper.
# Called on both normal exit and SIGINT; uses a per-invocation sentinel file to
# ensure only the first call decrements the ref-count.
#
# Args: sid state_dir lock_dir count_file ollama_pid_file manage_ollama manage_grepai
function _opencode_release
    set -l sid $argv[1]
    set -l state_dir $argv[2]
    set -l lock_dir $argv[3]
    set -l count_file $argv[4]
    set -l ollama_pid_file $argv[5]
    set -l manage_ollama_file $argv[6]
    set -l manage_grepai_file $argv[7]

    # Sentinel file prevents double-decrement when both the SIGINT handler and the
    # normal post-run path execute (fish resumes after the interrupted child exits).
    set -l released_file $state_dir/released.$sid
    if test -f $released_file
        return
    end
    command touch $released_file

    # Acquire the lock; treat a lock held for >~5s as stale and reclaim it.
    set -l _lock_attempts 0
    while not command mkdir $lock_dir 2>/dev/null
        set _lock_attempts (math $_lock_attempts + 1)
        if test $_lock_attempts -ge 100
            command rmdir $lock_dir 2>/dev/null
            set _lock_attempts 0
        end
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

function opencode
    set -l state_dir /tmp/opencode-state
    set -l lock_dir $state_dir/lock
    set -l count_file $state_dir/count
    set -l ollama_pid_file $state_dir/ollama.pid
    set -l manage_ollama_file $state_dir/ollama.manage
    set -l manage_grepai_file $state_dir/grepai.manage

    command mkdir -p $state_dir

    # Acquire the lock; treat a lock held for >~5s as stale (crashed session) and reclaim it.
    set -l lock_attempts 0
    while not command mkdir $lock_dir 2>/dev/null
        set lock_attempts (math $lock_attempts + 1)
        if test $lock_attempts -ge 100
            command rmdir $lock_dir 2>/dev/null
            set lock_attempts 0
        end
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

    # Unique per-invocation session ID, used to name the SIGINT handler and the
    # per-invocation sentinel file that prevents double-decrement.
    # fish inner functions are not closures — they cannot see `set -l` variables from
    # the enclosing scope. Instead of using dynamic global vars, we bake the paths
    # directly into the one-liner SIGINT handler body via eval, and pass them as
    # arguments to _opencode_release (a top-level function defined above).
    set -l oc_sid (random)

    # SIGINT handler: runs the release logic when the user presses Ctrl-C.
    # Terminal Ctrl-C sends SIGINT to both the foreground child and fish; the child
    # (opencode) dies and fish resumes after `command opencode $argv`, so the normal
    # release call below also executes. _opencode_release's sentinel file ensures only
    # the first call decrements the count.
    eval "function _opencode_sigint_$oc_sid --on-signal INT
        _opencode_release $oc_sid $state_dir $lock_dir $count_file $ollama_pid_file $manage_ollama_file $manage_grepai_file
    end"

    command opencode $argv

    # Normal exit path: deregister the signal handler, then run the release.
    functions -e _opencode_sigint_$oc_sid
    _opencode_release $oc_sid $state_dir $lock_dir $count_file $ollama_pid_file $manage_ollama_file $manage_grepai_file

    # Remove the sentinel file; safe to call even if the SIGINT path already cleaned up.
    command rm -f $state_dir/released.$oc_sid
end

# Path
fish_add_path ~/.bun/bin
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path /usr/local/bin
fish_add_path ~/.local/bin
fish_add_path ~/.orbstack/bin
fish_add_path ~/.opencode/bin

# NodeJS — managed by Vite+ (`vp env`). The vite-plus.fish snippet in conf.d
# adds ~/.vite-plus/bin to PATH; no NVM needed.

#VSCODE AND CURSOR
if test "$TERM_PROGRAM" = "vscode" -o "$TERM_PROGRAM" = "cursor"
    . (code --locate-shell-integration-path fish)
end

oh-my-posh init fish --config /opt/homebrew/opt/oh-my-posh/themes/jandedobbeleer.omp.json | source
