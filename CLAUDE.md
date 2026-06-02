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

Les configs Claude Code et Codex sont stockées dans ce repo et synchronisées par `setup_my_mac.sh` :

| Source (repo)         | Destination                  | Mode   |
|-----------------------|------------------------------|--------|
| `claude/CLAUDE.md`    | `~/.claude/CLAUDE.md`        | copy   |
| `claude/settings.json`| `~/.claude/settings.json`    | copy   |
| `claude/defaults.json`| `~/.claude.json`             | merge  |
| `claude/statusline.sh`| `~/.claude/statusline.sh`    | copy   |
| `claude/agents/`      | `~/.claude/agents/`          | sync   |
| `claude/rules/`       | `~/.claude/rules/`           | sync   |
| `claude/hooks/`       | `~/.claude/hooks/`           | sync   |
| `claude/commands/`    | `~/.claude/commands/`        | sync   |
| `claude/claudeignore.template` | `~/.claude/claudeignore.template` | copy |
| `codex/AGENTS.md`     | `~/.codex/AGENTS.md`         | copy   |
| `codex/config.toml`   | `~/.codex/config.toml`       | copy   |
| `codex/hooks.json`    | `~/.codex/hooks.json`        | copy   |
| `codex/agents/`       | `~/.codex/agents/`           | sync   |
| `codex/hooks/`        | `~/.codex/hooks/`            | sync   |

## Anti-patterns

- Ne pas modifier `~/.claude/` directement : modifier dans `claude/` et relancer le setup
- Ne pas modifier `~/.claude.json` via `/config` pour les préférences par défaut : modifier `claude/defaults.json` et relancer le setup
- Ne pas modifier `~/.codex/` directement : modifier dans `codex/` et relancer le setup
- Ne pas modifier `~/.config/fish/config.fish` directement : modifier `config.fish` dans le repo
