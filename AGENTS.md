# DOTFILES KNOWLEDGE BASE

**Generated:** 2025-12-29 | **Commit:** c39663a | **Branch:** master

## OVERVIEW

macOS dev environment bootstrap. Fish shell, Neovim, Bun, Node.js (NVM). Automated setup via single script.

## STRUCTURE

```
dotfiles/
├── setup_my_mac.sh     # Main bootstrap script (bash)
├── config.fish         # Fish shell config (copied to ~/.config/fish/)
├── init.vim            # Neovim config (copied to ~/.config/nvim/)
├── .gitconfig          # Git config (GPG signing)
├── .profile            # Bash/sh environment vars
├── .czrc               # Commitizen config
├── opencode/           # OpenCode AI agent config
│   ├── opencode.json   # Plugin list
│   ├── oh-my-opencode.json  # Agent settings
│   ├── AGENTS.md       # Global coding guidelines
│   └── command/        # Custom slash commands
└── .cursor/rules/      # Editor AI rules (Snyk)
```

## COMMANDS

```bash
./setup_my_mac.sh                              # Full bootstrap (new Mac)
upsys                                          # System update (after setup)
fish -c "source ~/.config/fish/config.fish"   # Apply fish config changes
bash -n setup_my_mac.sh                        # Validate bash syntax
fish -n config.fish                            # Validate fish syntax
```

**No test suite** — config repo. Validation via shell syntax check.

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add shell alias | `config.fish` L11-26 | alias section |
| Add brew package | `setup_my_mac.sh` L18 | `brew install` line |
| Add Fisher plugin | `setup_my_mac.sh` L62-63 | `fisher install` section |
| Add global npm pkg | `setup_my_mac.sh` L70 | `bun install -g` line |
| Change git settings | `.gitconfig` | Edit file directly |
| Modify vim settings | `init.vim` | Standard vimscript |
| Add PATH entry | `config.fish` L28-37 | `fish_add_path` section |

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
set --universal nvm_default_version lts # Universal for persistent settings
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
| Fish env vars | `UPPER_SNAKE` | `TERM`, `NVM_DIR` |

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
- **NVM via Fish plugin** — uses `jorgebucaran/nvm.fish`
- **Commitizen required** — use `cz` or `ga` for commits
- **Idempotent setup** — script safe to re-run

## ANTI-PATTERNS

| Don't | Do Instead |
|-------|------------|
| Edit `~/.config/fish/config.fish` directly | Edit `config.fish` in repo, re-run setup |
| Use `export PATH` in fish | Use `fish_add_path` |
| Use standard `nvm` commands | Use fish nvm: `nvm install lts` |
| Commit without GPG key | Set up key or disable `commit.gpgsign` |
| Use backticks for command substitution | Use `$()` syntax |

## ALIASES (Fish)

| Alias | Expansion | Purpose |
|-------|-----------|---------|
| `upsys` | `brew update && brew upgrade && brew cleanup && brew doctor && bun upgrade && bun -g update` | Full system update |
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

**Via Homebrew:** curl, wget, bash, git, vim, neovim, bun, fish, oh-my-posh, bat, eza, fd, ripgrep, ffmpeg, scrcpy, mole

**Via Cask:** android-platform-tools

**Via Bun (global):** eslint, prettier, ngrok, npm-check-updates, pm2, typescript, commitizen, cz-conventional-changelog, nx

**OpenCode plugins:** oh-my-opencode, opencode-supermemory, opencode-anthropic-auth

**Fonts:** JetBrains Mono Nerd Font, Symbols Only Nerd Font

**Fisher plugins:** `jorgebucaran/nvm.fish`, `rstacruz/fish-npm-global`

## NOTES

- Oh My Posh theme: `jandedobbeleer.omp.json`
- Orbstack path included: `~/.orbstack/bin`
- Warp terminal hook in config.fish for shell integration
- VSCode/Cursor shell integration auto-detected
