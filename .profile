if [ -x "/opt/homebrew/bin/brew" ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export OPENCODE_EXPERIMENTAL=true

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export PATH="$HOME/.opencode/bin:$BUN_INSTALL/bin:$HOME/.local/bin:$HOME/.node_modules/bin:$PATH"
export npm_config_prefix="$HOME/.node_modules"
