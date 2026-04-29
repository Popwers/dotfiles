# Dotfiles

Repo de bootstrap macOS. Voir `AGENTS.md` pour la knowledge base complète du projet (structure, conventions, aliases, outils installés).

## Conventions projet

- **Branche par défaut** : `master`
- **Shell principal** : Fish (pas bash/zsh pour l'usage interactif)
- **Pas de suite de tests** : validation via `bash -n setup_my_mac.sh` et `fish -n config.fish`
- **Idempotent** : le script de setup peut être relancé sans risque
- **GPG signing** : clé `AD871AD3647CE96D`
- **Commitizen** : utiliser `cz` ou `ga` pour les commits

## Fichiers de config gérés

Les configs Claude Code, Codex, OpenCode et Pi sont stockées dans ce repo et synchronisées par `setup_my_mac.sh` :

| Source (repo)         | Destination                  | Mode   |
|-----------------------|------------------------------|--------|
| `claude/CLAUDE.md`    | `~/.claude/CLAUDE.md`        | copy   |
| `claude/settings.json`| `~/.claude/settings.json`    | copy   |
| `claude/defaults.json`| `~/.claude.json`             | merge  |
| `claude/statusline.sh`| `~/.claude/statusline.sh`    | copy   |
| `claude/agents/`      | `~/.claude/agents/`          | sync   |
| `claude/rules/`       | `~/.claude/rules/`           | sync   |
| `claude/hooks/`       | `~/.claude/hooks/`           | sync   |
| `codex/AGENTS.md`     | `~/.codex/AGENTS.md`         |
| `codex/config.toml`   | `~/.codex/config.toml`       |
| `codex/hooks.json`    | `~/.codex/hooks.json`        |
| `codex/agents/`       | `~/.codex/agents/`           |
| `codex/hooks/`        | `~/.codex/hooks/`            |
| `opencode/`           | `~/.config/opencode/`        | sync   |
| `pi/AGENTS.md`        | `~/.pi/agent/AGENTS.md`      | copy   |
| `pi/settings.json`    | `~/.pi/agent/settings.json`  | copy   |
| `pi/mcp.json`         | `~/.pi/agent/mcp.json`       | copy   |
| `pi/agents/`          | `~/.pi/agent/agents/`        | sync   |
| `pi/extensions/`      | `~/.pi/agent/extensions/`    | sync   |

## Anti-patterns

- Ne pas modifier `~/.claude/` directement : modifier dans `claude/` et relancer le setup
- Ne pas modifier `~/.claude.json` via `/config` pour les préférences par défaut : modifier `claude/defaults.json` et relancer le setup
- Ne pas modifier `~/.codex/` directement : modifier dans `codex/` et relancer le setup
- Ne pas modifier `~/.config/opencode/` directement : modifier dans `opencode/` et relancer le setup
- Ne pas modifier `~/.pi/agent/` directement : modifier dans `pi/` et relancer le setup
- Ne pas modifier `~/.config/fish/config.fish` directement : modifier `config.fish` dans le repo
