eval "$(/opt/homebrew/bin/brew shellenv)"

export OPENCODE_EXPERIMENTAL=true

# Node managed by Vite+ — load its env for bash/zsh logins (no-op outside POSIX shells).
[ -s "$HOME/.vite-plus/env" ] && \. "$HOME/.vite-plus/env"

export PATH="$HOME/.node_modules/bin:$PATH"
export npm_config_prefix="$HOME/.node_modules"
