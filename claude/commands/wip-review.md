---
description: Self-review du travail en cours (WIP) — scope, anti-régression, audit, /code-review, fix. S'arrête avant commit pour laisser place aux tests manuels.
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git diff:*), Bash(git log:*)
---

Review du diff local avant que je le valide moi-même. Pas de push, pas de commit, pas de PR — juste s'assurer que ce que je viens de faire est solide et identifier ce que je dois tester manuellement.

## Contexte injecté

- Branche : !`git branch --show-current`
- Upstream : !`git rev-parse --abbrev-ref @{u} 2>/dev/null || echo "aucun"`
- Status : !`git status --short`
- Diff local (stat) : !`git diff HEAD --stat`
- Commits non-pushés : !`git log @{u}..HEAD --oneline 2>/dev/null || git log master..HEAD --oneline 2>/dev/null | head -15`

## 1. Détecter le scope

À partir du contexte injecté ci-dessus, par ordre de priorité :

1. Diff local (stat) non vide → le scope est `git diff HEAD`
2. Sinon, commits non-pushés avec upstream → `git diff @{u}...HEAD`
3. Sinon → `git diff master...HEAD` (depuis la divergence avec master)

Si tout est vide, demande à l'utilisateur ce qu'il veut review puis stoppe.

Une fois le diff identifié :

- Liste les fichiers touchés et les domaines impactés (UI, API, store, seed, schema, middleware, types générés, etc.)
- Lis le titre de la branche et les messages de commit récents pour comprendre l'intention
- Si monorepo (front + CMS), traite chaque package séparément

## 2. Anti-régression (priorité absolue)

C'est le point le plus important — c'est là que les bugs silencieux se cachent.

Pour chaque symbole modifié, renommé ou supprimé :

- Grep tous les call sites dans le repo (front + CMS + seed + types générés + tests + actions Astro)
- Note les fichiers qui n'apparaissent pas dans le diff mais qui consomment le symbole : ce sont les candidats à régression
- Si rename : confirme que les imports, ré-exports, fixtures de tests, et string literals (clés i18n, query params) suivent

Pour chaque écran/feature touchée :

- Liste les **autres** features qui partagent ce code (composants enfants, store, helpers communs)
- Pour chacune, identifie le flow utilisateur qui pourrait régresser (création / édition / suppression / navigation arrière / refresh / double-clic / formulaire vide)

Cette liste sera rappelée dans le rapport final sous "À tester manuellement".

## 3. Audit ciblé (subagents en parallèle)

Lance les deux subagents **en parallèle dans un seul message**, chacun avec la liste exacte des fichiers du scope :

- **`security-reviewer`** — auth + ownership sur les routes mutantes (create / update / delete), inputs validés à la frontière, secrets non commités, pas de stack trace leak côté client, pas de bypass de policy
- **`review-auditor`** — les quatre axes restants :
  - Type safety : 0 `as any`, 0 `@ts-ignore`, 0 cast non justifié. Si la lib force un typage loose (Strapi document API), `as never` est OK
  - Seeds & valeurs par défaut : tout nouveau champ obligatoire doit avoir une valeur par défaut dans le seed, et ne doit pas casser les rows existantes en prod
  - Perf : pas de N+1 query, pas de re-render en cascade sur Legend State (callbacks recréés, sélecteurs trop larges), pas de fetch dans une boucle
  - Robustesse serveur : validation produit toujours un feedback observable (throw, log warn, ou message user) — jamais de silent skip. Mutations multi-étapes transactionnelles

Exige des deux un retour compact au format `fichier:ligne — constat — sévérité`, sans extraits de code longs. Synthèse et fixes restent dans le contexte principal — les subagents ne modifient rien.

## 4. /code-review high + fix

- Lance `/code-review high` sur le diff identifié à l'étape 1
- Fix tous les findings **CRITICAL + HIGH + MEDIUM** dans le working tree
- Re-run `/code-review high` jusqu'à ce que ce soit clean (ou que les restes soient des LOW assumés)
- Les LOW restants : mentionne-les dans le rapport mais ne les fix pas automatiquement

## 5. Validation mécanique

- `vp check` → 0 erreur (lint + fmt + typecheck via `oxlint` + `oxfmt` + `tsgo`)
- `vp test` ciblé sur les fichiers touchés (skip si aucun test associé)
- `vp build` uniquement si un fichier de config build, un schema Strapi, ou un fichier de routing a bougé — sinon trop coûteux pour une self-review

## 6. Rapport final

**Tout en français. Bref, sans redite des critères.**

### Scope
- **Fichiers** : N modifiés
- **Domaines** : <liste 1 ligne>
- **Branche** : `<nom>` · **Intention** : <inférée du titre/commits>

### Risque de régression
Une ligne par feature à re-tester manuellement :
```
- <feature> — <flow concret> — <raison du risque>
```

Si rien : `Aucun risque identifié — diff isolé.`

### Audit
| Axe | Statut | Findings | Fixés |
|-----|--------|----------|-------|
| Sécurité | ✅/⚠️/❌ | … | … |
| Type safety | … | … | … |
| Seeds & défauts | … | … | … |
| Perf | … | … | … |
| Robustesse serveur | … | … | … |

Légende : ✅ PASS · ⚠️ PARTIAL · ❌ FAIL

### /code-review
- CRITICAL : N fixés / 0 restants
- HIGH : N fixés / 0 restants
- MEDIUM : N fixés / X restants (justifie chaque reste)
- LOW : X notés (non-fixés, listés ci-dessous si pertinent)

### Validation mécanique
- `vp check` : ✅/❌ (détail si ❌)
- `vp test` : ✅/❌/skip
- `vp build` : ✅/❌/skip (raison du skip)

### À tester manuellement avant commit
Liste numérotée concrète et actionnable :
```
1. <flow exact> dans <écran> — ex: créer un bien avec tous les champs, vérifier que les pièces s'enregistrent
2. …
```

Si UI : rappelle `vp dev` + `chrome-devtools-mcp` pour vérifier les erreurs console + network.

### Findings LOW non-fixés (optionnel)
Une ligne par finding, format `<fichier:ligne> — <constat>`.

## Garde-fous

- **Ne commit pas, ne push pas, ne stage pas** — l'utilisateur valide après tests manuels
- Pas de `--no-verify`, pas de `as any`, pas de suppression de tests qui passent plus pour faire passer le check
- Pas de refactor hors-scope — uniquement les fichiers déjà dans le diff de l'étape 1
- Si un fix demande >30 lignes de modification d'un seul tenant, surface-le en reco au lieu de l'appliquer
- Si bloqué : reporte ce que tu as essayé, l'erreur exacte, et la meilleure piste suivante. Pas de spirale

Procède.
