export OPENCODE_EXPERIMENTAL=true

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export PATH="$HOME/.opencode/bin:$BUN_INSTALL/bin:$HOME/.local/bin:$HOME/.node_modules/bin:$PATH"
export npm_config_prefix="$HOME/.node_modules"

if [ -s "$HOME/.nvm/nvm.sh" ]; then
	. "$HOME/.nvm/nvm.sh"
fi
