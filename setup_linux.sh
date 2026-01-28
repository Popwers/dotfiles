#!/usr/bin/env bash
set -euo pipefail

log() {
	echo "[setup_linux] $*"
}

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export PATH="$HOME/.opencode/bin:$BUN_INSTALL/bin:$HOME/.local/bin:$HOME/.node_modules/bin:$PATH"

is_root=false
if [ "$(id -u)" -eq 0 ]; then
	is_root=true
fi

if command -v apt-get >/dev/null 2>&1; then
	if [ "$is_root" = "true" ]; then
		log "Installing base packages (apt)"
		apt-get update
		apt-get install -y --no-install-recommends \
			bash \
			ca-certificates \
			curl \
			wget \
			git \
			openssh-client \
			build-essential \
			python3 \
			python3-venv \
			python3-pip \
			jq \
			unzip \
			zip \
			xz-utils \
			fish \
			neovim \
			bat \
			fd-find \
			ripgrep \
			rsync \
			procps
		rm -rf /var/lib/apt/lists/*
	else
		log "Skipping apt installs (not running as root)"
	fi
fi

if ! command -v bun >/dev/null 2>&1; then
	log "Installing Bun"
	curl -fsSL https://bun.sh/install | bash
fi

if [ -n "${BUN_INSTALL:-}" ] && [ ! -w "$BUN_INSTALL" ]; then
	if [ ! -x "$HOME/.bun/bin/bun" ]; then
		log "Installing Bun for user"
		BUN_INSTALL="$HOME/.bun" curl -fsSL https://bun.sh/install | bash
	fi
	export BUN_INSTALL="$HOME/.bun"
	export PATH="$BUN_INSTALL/bin:$PATH"
fi

if command -v fish >/dev/null 2>&1; then
	log "Configuring fish"
	fish -lc 'begin
		set -l has_fisher (functions -q fisher; and echo yes; or echo no)
		if test "$has_fisher" = "no"
			curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
			fisher install jorgebucaran/fisher
		end

		fisher install jorgebucaran/nvm.fish
		fisher install rstacruz/fish-npm-global

		if type -q nvm
			nvm install lts
			nvm use lts
		end

		if type -q bun
			bun add -g eslint prettier ngrok npm-check-updates pm2 typescript commitizen cz-conventional-changelog agent-browser @openai/codex
		end

		fish_add_path ~/.bun/bin
		fish_update_completions
	end'
fi

if ! command -v opencode >/dev/null 2>&1; then
	log "Installing OpenCode"
	curl -fsSL https://opencode.ai/install | bash
fi

if ! command -v grepai >/dev/null 2>&1; then
	log "Installing grepai"
	curl -sSL https://raw.githubusercontent.com/yoanbernabeu/grepai/main/install.sh | sh
fi

if command -v bunx >/dev/null 2>&1; then
	log "Installing OpenCode plugins and skills"
	bunx opencode-supermemory@latest install --no-tui

	bunx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser -g --all -y
	bunx skills add https://github.com/vercel-labs/agent-skills --skill web-design-guidelines -g --all -y
	bunx skills add https://github.com/anthropics/skills --skill frontend-design -g --all -y
	bunx skills add https://github.com/vercel-labs/skills --skill find-skills -g --all -y
	bunx skills add coreyhaines31/marketingskills -g --all -y
fi

if [ "${INSTALL_AGENT_BROWSER:-0}" = "1" ] && command -v agent-browser >/dev/null 2>&1; then
	log "Installing agent-browser Chromium"
	agent-browser install
fi

log "Linux setup complete"
