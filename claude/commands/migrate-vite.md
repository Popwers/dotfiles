---
description: Migrate the current repo to Vite+ (vp) via `vp migrate --no-interactive`, then layer Lionel's config + verify imports + clean residual legacy deps.
---

Migre ce projet vers Vite+ (`vp`). Le flow : on laisse `vp migrate` faire le gros du boulot (réécriture imports, génération `vite.config.ts`, hooks), puis on overlay les overrides Lionel + on nettoie ce que l'outil ne touche pas.

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

⚠️ **Vite+ ne remplace PAS les CLI de meta-frameworks**. `vp dev` lance Vite nu — les meta-frameworks possèdent l'instance Vite et ajoutent routing/SSR/adapters/intégrations que `vp dev` n'exécute pas.

- **Garde la CLI propre** : Astro (`astro dev/build/check`), Next.js (`next dev/build`, Turbopack — pas Vite du tout), Nuxt (`nuxt dev/build`), SvelteKit (`bun run dev` → `vite dev` avec config SvelteKit), SolidStart (`bun run dev` → `vinxi dev`), TanStack **Start** (`bun run dev` → Vinxi).
- **Utilise `vp dev` / `vp build`** : Vite-SPA pur, lib Vite, ou Vite + plugins isolés (ex. TanStack **Router** standalone via `@tanstack/router-vite-plugin`).

## Référence de config Lionel

Surcouche standard (Oxfmt tabs/single-quote + Oxlint + staged + build esnext + per-package vendor chunks) à overlay sur la config générée par `vp migrate` :
https://gist.githubusercontent.com/Popwers/e112d96aea101e5aa35311048644d9cf/raw/vite.config.ts

```sh
curl -fsSL https://gist.githubusercontent.com/Popwers/e112d96aea101e5aa35311048644d9cf/raw/vite.config.ts > /tmp/vite.config.lionel.ts
```

## Procédure

### A. Prérequis

1. **Lis les capabilities** :
   ```sh
   vp help
   vp help migrate
   ```

2. **Vérifie les versions** (`vp migrate` exige Vite ≥ 8 et Vitest ≥ 4.1) :
   ```sh
   bun pm ls vite vitest 2>/dev/null || bunx --bun list vite vitest
   ```
   Si en-dessous, upgrade avant de continuer :
   ```sh
   bun add -d vite@latest vitest@latest
   ```

### B. Migration automatique

3. **Lance la migration officielle depuis la racine workspace** :
   ```sh
   vp migrate --no-interactive
   ```
   → réécrit `vite.config.*`, déplace les configs tool-specific dans des blocs, installe les git hooks, et **réécrit les imports** (`vite` → `vite-plus`, `vitest` → `vite-plus/test`).

### C. Vérifications post-migration

4. **Confirme la réécriture des imports** (aucun match attendu, sauf dans `vite.config.ts`) :
   ```sh
   rg "from ['\"]vite['\"]" --type ts --type tsx --type js --type jsx -g '!vite.config.*' -g '!node_modules'
   rg "from ['\"]vitest['\"]" --type ts --type tsx --type js --type jsx -g '!node_modules'
   ```
   Si des matches restent, réécris-les à la main vers `vite-plus` / `vite-plus/test`.

5. **Retire `vite` et `vitest`** maintenant que les imports sont propres :
   ```sh
   bun remove vite vitest
   ```

6. **Nettoyage residual legacy** (deps que `vp migrate` ne supprime pas toutes — croise avec le `package.json` réel) :
   ```sh
   bun remove eslint @biomejs/biome rome prettier dprint husky lefthook simple-git-hooks lint-staged @commitlint/cli @commitlint/config-conventional typescript jest ts-jest babel-jest tsx ts-node 2>/dev/null || true
   ```

7. **Retire les configs orphelines** que `vp migrate` peut avoir laissées :
   ```sh
   rm -f biome.json rome.json .prettierrc* .prettierignore .eslintrc* .eslintignore commitlint.config.* .lintstagedrc* lefthook.yml .pre-commit-config.yaml dprint.json jest.config.*
   rm -rf .husky/
   ```

### D. Overlay config Lionel

8. **Compare la config générée à la référence** :
   ```sh
   diff vite.config.ts /tmp/vite.config.lionel.ts
   ```

9. **Merge manuellement les blocs Lionel manquants** dans `vite.config.ts` (sans casser ce que `vp migrate` a généré) :
   - `format:` (tabs, single-quote, semis, trailing comma all, sortTailwindcss)
   - `lint:` (Oxlint rules + overrides Astro/Svelte)
   - `build:` (target `esnext`, `modulePreload.polyfill: false`, `manualChunks` per-package vendor)
   - `staged:` (pattern → `vp check --fix`)

### E. Alignement Makefile (si présent)

Si un `Makefile` existe à la racine, aligne les targets qui wrappent l'outillage node vers `vp`. Mapping courant :

| Target           | Avant                                  | Après                                              |
|------------------|----------------------------------------|----------------------------------------------------|
| `install`        | `bun install` / `npm install`          | `vp install`                                       |
| `dev`            | `bun run dev` / `vite`                 | `vp dev` (ou CLI framework si meta-framework)      |
| `build`          | `bun run build` / `vite build`         | `vp build` (ou CLI framework)                      |
| `preview`        | `vite preview`                         | `vp preview`                                       |
| `test`           | `bun test` / `vitest` / `jest`         | `vp test` (built-in Vitest)                        |
| `lint`           | `eslint .` / `biome lint .`            | `vp lint` (ou `vp check` si combiné)               |
| `fmt` / `format` | `prettier --write .` / `biome fmt .`   | `vp fmt`                                           |
| `typecheck`      | `tsc --noEmit`                         | inclus dans `vp check`                             |
| `check` / `ci`   | chaîne d'outils                        | `vp check && vp test`                              |
| `clean`          | custom                                 | inchangé                                           |

10. **Patch les targets concernées** dans le `Makefile`, en gardant les targets qui orchestrent du non-vp (`docker`, `migrate db`, scripts shell custom). Si une target dépendait d'un script `package.json` retiré au step C, redirige-la directement vers la commande `vp` équivalente plutôt que via `vp run <script>`.

### F. Polish & validation

11. **Fix tsconfig pour tsgolint** (résout les soucis `baseUrl` que tsgo refuse) :
    ```sh
    bunx @andrewbranch/ts5to6 --fixBaseUrl .
    ```

12. **Nettoyage global du code** (Oxfmt + auto-fix Oxlint sur tout le repo) :
    ```sh
    vp check --fix
    ```

13. **Valide la chaîne complète** :
    ```sh
    vp install
    vp check    # lint + fmt + typecheck (sans --fix)
    vp test     # si applicable
    vp build    # si applicable
    ```

### G. Commits (via `cz` ou `ga`)

14. **Découpe en commits cohérents** :
    - `chore: drop legacy stack (husky, biome, commitlint, prettier, eslint, ...)` — suppressions de deps + configs
    - `feat(toolchain): adopt Vite+ (vp) for lint/fmt/typecheck/hooks` — `vite.config.ts` + `.vite-hooks/` + imports `vite-plus`

## Garde-fous

- **Ne supprime PAS `vite`/`vitest` avant l'étape 5** — `vp migrate` réécrit les imports vers `vite-plus`, mais si tu retires les packages avant vérification, le build casse.
- **Conventional commits** : `cz` / `ga` à l'authoring, plus de `commit-msg` hook.
- **CI** : workflows GitHub qui appellent `bunx biome`, `bun run lint`, `npm run typecheck`, etc. → remplace par `vp check`.
- **Monorepo** : applique la migration sous-projet par sous-projet, chacun avec son `vite.config.ts`. `vp run <task>` peut remplacer Turbo/Nx pour le task running au niveau racine.

## Format attendu en sortie

Pour chaque sous-projet migré :
- Versions avant/après (`vite`, `vitest`)
- Imports réécrits (count `vite` → `vite-plus`, `vitest` → `vite-plus/test`)
- Fichiers supprimés (liste)
- Deps supprimées (liste)
- Diff du `package.json` scripts
- Résultat de `vp check` (PASS / liste d'issues si FAIL)
- Manual follow-up restant (si applicable)

Pas de filler. Procède.
