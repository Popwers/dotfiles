---
description: Migrate the current repo to Vite+ (vp), replacing husky/biome/prettier/eslint/commitlint/lint-staged with a single vite.config.ts.
---

Migre ce projet vers Vite+ (`vp`). Objectif : un seul `vite.config.ts` remplace husky, lint-staged, @biomejs/biome, prettier, @commitlint, eslint, et l'install global de typescript.

## Référence de config

La config standard de Lionel (Oxfmt + Oxlint + staged + build esnext + per-package vendor chunks) est sur ce gist :
https://gist.githubusercontent.com/Popwers/e112d96aea101e5aa35311048644d9cf/raw/vite.config.ts

Récupère-la avec :
```sh
curl -fsSL https://gist.githubusercontent.com/Popwers/e112d96aea101e5aa35311048644d9cf/raw/vite.config.ts > vite.config.ts
```

## Procédure (suis-la dans l'ordre)

1. **Inventaire** : liste les fichiers et deps à supprimer
   - Configs à dégager : `biome.json`, `.prettierrc*`, `.eslintrc*`, `commitlint.config.*`, `.lintstagedrc*`, `.husky/`
   - Deps à retirer du `package.json` : `husky`, `lint-staged`, `@biomejs/biome`, `prettier`, `@commitlint/cli`, `@commitlint/config-conventional`, `eslint*`, `typescript` (si déplacé global vers `vp env`)
   - Scripts `package.json` à nettoyer : tout ce qui appelle `biome`, `prettier`, `eslint`, `husky`, `lint-staged`, `commitlint`, ou `tsc` direct
   - Garde : `dev`, `build`, `test` si ces scripts appellent un framework (ex. `astro dev` / `astro build`). Sinon remplace par `vp dev` / `vp build` / `vp test`.

2. **Récupère le `vite.config.ts` de référence** (commande curl ci-dessus).
   - Si le repo a des spécificités (ex. Astro, monorepo), garde la base et ajoute uniquement les overrides nécessaires.
   - Repos Astro : l'override `lint.overrides` pour `**/*.astro` est déjà présent.

3. **Retire les deps** :
   ```sh
   bun remove husky lint-staged @biomejs/biome prettier @commitlint/cli @commitlint/config-conventional eslint typescript 2>/dev/null || true
   # Adapte si le PM est pnpm / npm
   ```

4. **Retire les configs obsolètes** :
   ```sh
   rm -f biome.json .prettierrc* .prettierignore .eslintrc* .eslintignore commitlint.config.* .lintstagedrc*
   rm -rf .husky/
   ```

5. **Installe les git hooks Vite+** :
   ```sh
   vp config
   ```
   → crée `.vite-hooks/pre-commit` qui exécute le bloc `staged:` de `vite.config.ts`.

6. **Réinstalle proprement** :
   ```sh
   vp install
   ```

7. **Valide** :
   ```sh
   vp check    # lint + fmt + typecheck
   vp test     # si applicable
   vp build    # si applicable
   ```

8. **Commits** :
   - Premier commit : `chore: drop legacy stack (husky, biome, commitlint, prettier, eslint)` — supprime les fichiers
   - Deuxième commit : `feat(toolchain): adopt Vite+ (vp) for lint/fmt/typecheck/hooks` — ajoute `vite.config.ts` + `.vite-hooks/`
   - Utilise `cz` ou `ga` (commitizen).

## Garde-fous

- **Ne pas migrer si** : le repo a des règles biome/eslint custom critiques que Oxlint ne supporte pas (vérifie d'abord avec `vp check`).
- **Conventional commits** : viennent maintenant de `cz` / `ga` à l'authoring, plus de `commit-msg` hook.
- **CI** : si des workflows GitHub appellent `bunx biome` ou `bun run lint`, remplace par `vp check`.
- **Monorepo** : si plusieurs sous-projets, applique la migration sous-projet par sous-projet, chacun avec son propre `vite.config.ts`.

## Format attendu en sortie

Pour chaque sous-projet migré, donne :
- Fichiers supprimés (liste)
- Deps supprimées (liste)
- Diff du `package.json` scripts
- Résultat de `vp check` (PASS / liste d'issues si FAIL)
- Commit hash des deux commits

Pas de filler. Procède.
