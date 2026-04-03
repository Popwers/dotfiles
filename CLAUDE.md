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

Les configs Claude Code, Codex et OpenCode sont stockées dans ce repo et synchronisées par `setup_my_mac.sh` :

| Source (repo)         | Destination                  |
|-----------------------|------------------------------|
| `claude/CLAUDE.md`    | `~/.claude/CLAUDE.md`        |
| `claude/settings.json`| `~/.claude/settings.json`    |
| `claude/ccline/`      | `~/.claude/ccline/`          |
| `claude/agents/`      | `~/.claude/agents/`          |
| `codex/AGENTS.md`     | `~/.codex/AGENTS.md`         |
| `codex/config.toml`   | `~/.codex/config.toml`       |
| `codex/hooks.json`    | `~/.codex/hooks.json`        |
| `codex/agents/`       | `~/.codex/agents/`           |
| `codex/hooks/`        | `~/.codex/hooks/`            |

## Anti-patterns

- Ne pas modifier `~/.claude/` directement : modifier dans `claude/` et relancer le setup
- Ne pas modifier `~/.codex/` directement : modifier dans `codex/` et relancer le setup
- Ne pas modifier `~/.config/fish/config.fish` directement : modifier `config.fish` dans le repo
