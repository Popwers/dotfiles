# My Mac Development Setup

This repository contains scripts and configuration files for setting up a development environment on macOS. The setup includes various tools, package managers, and configurations to enhance productivity and streamline the development workflow.

## Setup Script

The `setup_my_mac.sh` script automates the installation and configuration of various tools and utilities. Here's an overview of what it does:

1. Installs and updates Homebrew
2. Installs essential packages and tools
3. Sets up fonts (JetBrains Mono Nerd Font and Symbols Only Nerd Font)
4. Configures Fish shell as the default shell
5. Installs Fisher (plugin manager for Fish)
6. Installs Vite+ (`vp`) — manages Node.js (`vp env`) and unifies build, dev, lint, fmt, typecheck, and test
7. Installs global npm packages using Bun
8. Installs GrepAI and sets up Ollama embeddings (`nomic-embed-text`)
9. Creates and configures `.profile`, `config.fish`, `.czrc`, and `init.vim` files

To run the setup script:

```bash
./setup_my_mac.sh
```

## Fish Shell Configuration

The Fish shell is configured with various aliases, path settings, and integrations. Key features include:

- Custom greeting (disabled)
- Aliases for common commands and navigation
- Path configurations for Homebrew, local binaries, and Node.js
- Integration with Oh My Posh for a customized prompt
- VSCode and Cursor shell integration
- Custom `git` function to use Commitizen for commits

For more details, see the `config.fish` file

## Profile Configuration

The `.profile` file is set up with environment variables for Homebrew, Vite+ (`~/.vite-plus`), and npm. It ensures that these tools are properly loaded and configured in the shell environment.

## Installed Tools and Utilities

The setup includes various tools and utilities to enhance the development experience:

- Homebrew (package manager)
- Git, Vim, Neovim
- Fish shell with Oh My Posh
- Bun (JavaScript runtime and toolkit)
- Bat (alternative to `cat`)
- Eza (modern replacement for `ls`)
- Fd (modern replacement for `find`)
- Ripgrep (modern replacement for `grep`)
- FFmpeg (video/audio processing)
- Scrcpy (Android screen mirroring)
- Mole (SSH tunnel manager)
- Claude Code (AI coding agent for terminal)
- GrepAI (semantic code search)
- Ollama (local embeddings for GrepAI)
- Android Platform Tools (ADB, fastboot)
- Node.js (via Vite+ `vp env`)
- Vite+ (`vp`) — unified Vite/Vitest/Oxlint/Oxfmt/tsgo toolchain
- Global npm packages: ngrok, npm-check-updates, commitizen, cz-conventional-changelog, @openai/codex

## Claude Code

Claude Code is installed globally through Bun as `@anthropic-ai/claude-code`. The shared skills installer links the same skills into Claude Code and Codex. Claude Code keeps its dedicated instructions in `claude/CLAUDE.md`.

## Codex

Codex has its own dedicated global instructions in `codex/AGENTS.md`, copied to `~/.codex/AGENTS.md` during setup.
Codex configuration is stored in `codex/config.toml` and copied to `~/.codex/config.toml` during setup.
Codex hooks live in `codex/hooks.json` and `codex/hooks/`, and are synced to `~/.codex/`.
Because Codex hooks are currently Bash-oriented, the validation hooks are implemented as a best-effort shared pipeline: helper startup, command gates, auto-format, typecheck, targeted tests, `as any` scan, UI anti-pattern scan, stop-quality check, and grepai watcher shutdown.
Custom subagents live in `codex/agents/` and are synced to `~/.codex/agents/` during setup.
Codex also falls back to repo-level `CLAUDE.md` files when `AGENTS.md` is missing, which makes older Claude-oriented repos usable without extra migration.
The Codex agent set mirrors the Claude setup closely: `repo-explorer`, `review-auditor`, `test-guardian`, `change-implementer`, `docs-researcher`, `planner`, `performance-optimizer`, and `security-reviewer`.
Subagents should stay token-efficient: use targeted discovery (`grepai`, `rg`, `fd`), read narrow line ranges, and return concise summaries instead of large raw outputs.

## Cross-agent instruction alignment

Claude Code and Codex should keep the same core instructions, frontend skill order, validation expectations, and response contract unless their runtime requires a tool-specific addendum.

## Fonts

The setup installs JetBrains Mono Nerd Font and Symbols Only Nerd Font, which are optimized for development environments and terminal use.

## Neovim Configuration

A basic Neovim configuration is provided in the `init.vim` file, which includes settings for:

- File searching and encoding
- Line numbers and indentation
- Performance optimizations
- Search behavior
- Folding
- Clipboard integration
- Mouse support
- Transparent background

## Commitizen Configuration

The `.czrc` file is set up to use the `cz-conventional-changelog` adapter for Commitizen, ensuring consistent commit messages.

## Customization

Feel free to modify the `setup_my_mac.sh`, `config.fish`, `.profile`, `init.vim`, or `.czrc` files to suit your specific needs. You can add or remove packages, change aliases, or adjust environment variables as needed.

## Maintenance

To keep your system up-to-date, you can use the `upsys` alias, which updates Homebrew packages and global npm packages:

```fish
upsys
```

This alias runs the following commands:
- `brew update && brew upgrade && brew cleanup && brew doctor`
- `bun -g update`

Enjoy your new development environment !
