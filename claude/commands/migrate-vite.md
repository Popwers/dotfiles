---
description: Migrate the current repo to Vite+ (vp), replacing the legacy lint/fmt/test/typecheck/hooks stack with a single vite.config.ts.
---

Migre ce projet vers Vite+ (`vp`). Un seul `vite.config.ts` remplace tout l'ancien outillage de qualité de code.

## Ce que Vite+ remplace

| Rôle             | Outils legacy supprimés                                                                          | Vite+ équivalent           |
|------------------|--------------------------------------------------------------------------------------------------|----------------------------|
| Linter           | `eslint*`, `@biomejs/biome`, `rome`, `@rome/*`                                                   | `vp check` (Oxlint)        |
| Formatter        | `prettier`, `dprint`, `@biomejs/biome`                                                           | `vp check` (Oxfmt)         |
| Typecheck        | `typescript` (global), `tsc`                                                                     | `vp check` (tsgo)          |
| Tests            | `vitest` (le package), `jest`, `@jest/*`, `ts-jest`, `babel-jest`                                | `vp test` (Vitest bundlé)  |
| Git hooks        | `husky`, `lefthook`, `simple-git-hooks`, `pre-commit`                                            | `vp config` → `.vite-hooks/` |
| Staged checks    | `lint-staged`, `nano-staged`                                                                     | bloc `staged:` du config   |
| Commits          | `@commitlint/cli`, `@commitlint/config-conventional`                                             | `cz` / `ga` (commitizen)   |
| TS runtime       | `tsx`, `ts-node`, `esbuild-runner`                                                               | `vp env` / `bun`           |
| Monorepo runner  | `turbo`, `nx`, `lerna` (uniquement pour `run`)                                                   | `vp run <task>` (optionnel)|

⚠️ **Vite+ ne remplace PAS les CLI de framework**. `vp dev` lance Vite directement sans charger `astro.config.mjs`, `next.config.js`, `nuxt.config.ts`, `svelte.config.js`, etc. **Garde les scripts `astro dev`, `astro build`, `astro check`** (idem pour Next, Nuxt, SvelteKit, TanStack Start, SolidStart). Ne remplace par `vp dev` / `vp build` que si le repo appelle `vite` directement (Vite-SPA pur ou lib).

## Référence de config

La config standard de Lionel (Oxfmt + Oxlint + staged + build esnext + per-package vendor chunks) est sur ce gist :
https://gist.githubusercontent.com/Popwers/e112d96aea101e5aa35311048644d9cf/raw/vite.config.ts

```sh
curl -fsSL https://gist.githubusercontent.com/Popwers/e112d96aea101e5aa35311048644d9cf/raw/vite.config.ts > vite.config.ts
```

## Procédure

1. **Inventaire**
   - Configs à dégager : `biome.json`, `rome.json`, `.prettierrc*`, `.prettierignore`, `.eslintrc*`, `.eslintignore`, `commitlint.config.*`, `.lintstagedrc*`, `.husky/`, `lefthook.yml`, `.pre-commit-config.yaml`, `dprint.json`, `jest.config.*`
   - Deps à retirer : voir le tableau ci-dessus (croise avec le `package.json` réel).
   - Scripts `package.json` à nettoyer : tout ce qui appelle `eslint`, `biome`, `prettier`, `husky`, `lint-staged`, `commitlint`, `tsc`, `jest`, `tsx`, `ts-node` directement.

2. **Récupère le `vite.config.ts` de référence** (commande curl ci-dessus). Garde la base telle quelle, ajoute uniquement des overrides si une spécificité du repo le justifie (rare).

3. **Retire les deps** :
   ```sh
   bun remove eslint @biomejs/biome rome prettier dprint husky lefthook simple-git-hooks lint-staged @commitlint/cli @commitlint/config-conventional typescript vitest jest ts-jest babel-jest tsx ts-node 2>/dev/null || true
   # Adapte si le PM est pnpm / npm
   ```

4. **Retire les configs obsolètes** :
   ```sh
   rm -f biome.json rome.json .prettierrc* .prettierignore .eslintrc* .eslintignore commitlint.config.* .lintstagedrc* lefthook.yml .pre-commit-config.yaml dprint.json jest.config.*
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

7. **Nettoyage global du code** (formatte tout le repo selon Oxfmt + auto-fix Oxlint) :
   ```sh
   vp check --fix
   ```

8. **Valide** :
   ```sh
   vp check    # lint + fmt + typecheck (sans --fix)
   vp test     # si applicable
   vp build    # si applicable
   ```

9. **Commits** (via `cz` ou `ga`) :
   - `chore: drop legacy stack (husky, biome, commitlint, prettier, eslint, ...)` — fichiers supprimés
   - `feat(toolchain): adopt Vite+ (vp) for lint/fmt/typecheck/hooks` — `vite.config.ts` + `.vite-hooks/`

## Garde-fous

- **Conventional commits** : viennent maintenant de `cz` / `ga` à l'authoring, plus de `commit-msg` hook.
- **CI** : si des workflows GitHub appellent `bunx biome`, `bun run lint`, `npm run typecheck`, etc., remplace par `vp check`.
- **Monorepo** : applique la migration sous-projet par sous-projet, chacun avec son propre `vite.config.ts`. `vp run` peut remplacer Turbo/Nx pour le task running au niveau racine.

## Format attendu en sortie

Pour chaque sous-projet migré :
- Fichiers supprimés (liste)
- Deps supprimées (liste)
- Diff du `package.json scripts`
- Résultat de `vp check` (PASS / liste d'issues si FAIL)

Pas de filler. Procède.
