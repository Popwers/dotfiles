# DOTFILES KNOWLEDGE BASE

**Generated:** 2026-06-11 | **Commit:** 0b09386 | **Branch:** master

## OVERVIEW

macOS dev environment bootstrap. Fish shell, Neovim, Bun, Node.js (via Vite+ `vp env`). Automated setup via single script.

## STRUCTURE

```
dotfiles/
├── setup_my_mac.sh     # Main bootstrap script (bash)
├── config.fish         # Fish shell config (copied to ~/.config/fish/)
├── init.vim            # Neovim config (copied to ~/.config/nvim/)
├── .gitconfig          # Git config (GPG signing)
├── .profile            # Bash/sh environment vars
├── .czrc               # Commitizen config
├── claude/             # Claude Code config (synced to ~/.claude/)
│   ├── CLAUDE.md       # Global agent instructions
│   ├── settings.json   # Global settings
│   ├── defaults.json   # Merged into ~/.claude.json (model defaults etc.)
│   ├── statusline.sh   # Status line script for Claude Code
│   ├── claudeignore.template  # Template for per-project .claudeignore
│   ├── agents/         # Custom subagents
│   ├── commands/       # Custom slash commands
│   ├── hooks/          # Lifecycle hook scripts
│   └── rules/          # Reusable rule files (code quality, git, etc.)
├── codex/              # Codex config (synced to ~/.codex/)
│   ├── AGENTS.md       # Global Codex instructions
│   ├── config.toml     # Central config
│   ├── hooks.json      # Codex lifecycle hooks config
│   ├── hooks/          # Hook scripts
│   └── agents/         # Custom subagents
├── .vscode/            # Project-level VS Code / Cursor config (Vite+ / Oxc)
│   ├── extensions.json # Recommended extensions
│   └── settings.json   # Default formatter, code actions, npm.scriptRunner
└── .cursor/rules/      # Editor AI rules (Snyk)
```

## COMMANDS

```bash
./setup_my_mac.sh                              # Full bootstrap (new Mac)
upsys                                          # System update (after setup)
fish -c "source ~/.config/fish/config.fish"   # Apply fish config changes
bash -n setup_my_mac.sh                        # Validate bash syntax
fish -n config.fish                            # Validate fish syntax
./verify.sh                                    # One-command validation (syntax checks + quick sanity)
```

**No test suite** — config repo. Validation via shell syntax check.

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add shell alias | `config.fish` L9-23 | alias section |
| Add brew package | `setup_my_mac.sh` L41 | `brew_formulas=(...)` array |
| Add Fisher plugin | `setup_my_mac.sh` L156-157 | `fisher install` section |
| Add global npm pkg | `setup_my_mac.sh` L171-180 | `for pkg in` loop, `bun install -g` at L180 |
| Change git settings | `.gitconfig` | Edit file directly |
| Modify vim settings | `init.vim` | Standard vimscript |
| Add PATH entry | `config.fish` L135-141 | `fish_add_path` section (includes `~/.opencode/bin`) |

## CODE STYLE

### Bash (setup_my_mac.sh)

```bash
if test ! $(which brew); then          # Use $() not backticks
echo "$variable"                        # Quote variables
if [ -f "$HOME/Library/Fonts/$f" ]; then  # POSIX test syntax
install_font() { local font_name=$1; }  # Functions: snake_case
cat << EOF > ~/.config/fish/config.fish # Heredocs for multi-line
```

### Fish (config.fish)

```fish
set -gx TERM xterm-256color            # Variables: set not export
fish_add_path /opt/homebrew/bin        # Path: fish_add_path, not export PATH
alias ls "eza --long --icons --all"    # Aliases: use alias keyword
if test "$TERM_PROGRAM" = "vscode"     # Conditionals: use test
set --universal fish_greeting ""        # Universal for persistent settings
```

### Vimscript (init.vim)

```vim
" Comments start with double-quote
set relativenumber                      " No spaces around =
highlight Normal guibg=NONE ctermbg=NONE
```

## NAMING CONVENTIONS

| Type | Convention | Example |
|------|------------|---------|
| Bash functions | `snake_case` | `install_font` |
| Bash variables | `snake_case` | `font_name`, `cask_name` |
| Fish aliases | `lowercase` | `upsys`, `ga`, `cz` |
| Fish env vars | `UPPER_SNAKE` | `TERM`, `VP_HOME` |

## ERROR HANDLING

```bash
if test ! $(which brew); then           # Check command existence
if [ -f "$HOME/Library/Fonts/$f" ]; then  # Check file existence
if ! grep -q $(which fish) /etc/shells; then  # Check before modifying
```

## CURSOR RULES (.cursor/rules/)

### Snyk Security (snyk_rules.mdc)

- Run `snyk_code_scan` tool for new first party code in Snyk-supported languages
- Fix security issues using Snyk results context
- Rescan after fixes until clean
- Applies to: all files (`**`)

## CONVENTIONS

- **Fish shell primary** — not bash/zsh for interactive use
- **GPG commit signing** — requires key `AD871AD3647CE96D`
- **master branch** — default is `master`, not `main`
- **Node + JS toolchain via Vite+** — `vp env` manages Node; `vp check` / `vp test` / `vp build` cover lint, fmt, typecheck, test, build
- **Commit hooks via Vite+** — `vp config` installs Git hooks into `.vite-hooks/`; staged checks declared in `vite.config.ts` under `staged:`
- **Commitizen required** — use `cz` or `ga` for commits (conventional-commit format comes from authoring, not from a `commit-msg` hook)
- **Idempotent setup** — script safe to re-run

## ANTI-PATTERNS

| Don't | Do Instead |
|-------|------------|
| Edit `~/.config/fish/config.fish` directly | Edit `config.fish` in repo, re-run setup |
| Use `export PATH` in fish | Use `fish_add_path` |
| Use `nvm` / standalone Node installers | Use `vp env use lts` to switch the managed Node |
| Install `husky` / `lint-staged` / `@biomejs/biome` / `@commitlint/*` per project | Use `vp config` + `staged:` block in `vite.config.ts` |
| Wire `.husky/pre-commit` and `.husky/commit-msg` manually | Let `vp config` write Git hooks into `.vite-hooks/`; author via `cz`/`ga` |
| Commit without GPG key | Set up key or disable `commit.gpgsign` |
| Use backticks for command substitution | Use `$()` syntax |

## ALIASES (Fish)

| Alias | Expansion | Purpose |
|-------|-----------|---------|
| `upsys` | `brew … && bun upgrade && bun -g update && vp env install lts` | Full system update (incl. managed Node LTS) |
| `ga` | `git add . && git cz` | Stage all + commitizen |
| `cz` | `git cz` | Commitizen commit |
| `ls`, `l` | `eza --long --color=always --icons=always --all` | Enhanced listing |
| `lss` | `eza --long --all --total-size --sort=size` | List by size |
| `cat` | `bat` | Syntax-highlighted cat |
| `vim`, `vi` | `nvim` | Use neovim |

## GIT ALIASES (.gitconfig)

| Alias | Command | Usage |
|-------|---------|-------|
| `git st` | `status` | Quick status |
| `git co` | `checkout` | Switch branches |
| `git br` | `branch` | List branches |
| `git cm` | `commit` | Commit |
| `git df` | `diff` | Show diff |
| `git lg` | `log --graph --pretty=...` | Pretty log |
| `git pr` | `pull --rebase` | Pull with rebase |
| `git amend` | `commit --amend --no-edit` | Amend last commit |

## INSTALLED TOOLS

**Via Homebrew:** curl, wget, bash, git, gh, vim, neovim, bun, fish, oh-my-posh, bat, eza, fd, ripgrep, ffmpeg, scrcpy, mole, rtk, uv

**Via uv (tools):** serena-agent (Serena — LSP-based symbolic navigation MCP for Claude Code + Codex), graphifyy (Graphify — one-shot knowledge-graph maps, `/graphify` skill in Claude Code)

**Via Cask:** android-platform-tools, ollama-app (replaces broken `ollama` formula; also pulls the `nomic-embed-text` embedding model via `ollama pull`)

**Via Bun (global):** ngrok, npm-check-updates, commitizen, cz-conventional-changelog, @openai/codex, impeccable

**Via official installer:** Claude Code (`curl -fsSL https://claude.ai/install.sh | bash`), grepai (`curl -sSL https://raw.githubusercontent.com/yoanbernabeu/grepai/main/install.sh | sh`)

**Codex fallbacks:** `CLAUDE.md` is accepted as a fallback project instruction file when `AGENTS.md` is missing

**Fonts:** JetBrains Mono Nerd Font, Symbols Only Nerd Font

**Fisher plugins:** none (legacy `jorgebucaran/nvm.fish` removed in favour of Vite+ managed Node)

## NOTES

- Oh My Posh theme: `jandedobbeleer.omp.json`
- Orbstack path included: `~/.orbstack/bin`
- Warp terminal hook in config.fish for shell integration
- VSCode/Cursor shell integration auto-detected
