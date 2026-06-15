---
description: Met à jour les dépendances du repo courant — upgrade natif du framework, puis ncu (mineures groupées, majeures une par une avec lecture de la doc de migration), validation réelle derrière chaque étape, commit conventionnel.
allowed-tools: Bash(ls:*), Bash(grep:*), Bash(git status:*), Bash(git rev-parse:*), Bash(ncu:*), Bash(cat:*)
---

Met à jour les dépendances du repo courant **avec prudence et validation réelle**. Jamais un `ncu -u` aveugle : on sépare le sûr du cassant, on lit la doc des majeures, et on prouve que ça marche avant de committer.

## Contexte injecté

- Racine git : !`git rev-parse --show-toplevel 2>/dev/null || echo "(pas un repo git)"`
- Arbre propre ? : !`git status --short 2>/dev/null || echo "(n/a)"`
- Manifests : !`ls package.json bun.lock* package-lock.json pnpm-lock.* yarn.lock vite.config.* astro.config.* svelte.config.* next.config.* nuxt.config.* 2>/dev/null || echo "aucun"`
- Package manager : !`grep -m1 '"packageManager"' package.json 2>/dev/null || echo "(non déclaré — déduire du lockfile)"`
- Frameworks détectés : !`grep -oE '"(astro|next|nuxt|@sveltejs/kit|svelte|vue|@tanstack/react-start|@tanstack/start|react|react-dom|@strapi/strapi|strapi|@legendapp/state|better-auth|drizzle-orm)"' package.json 2>/dev/null | sort -u || echo "(aucun)"`
- Mises à jour disponibles : !`ncu 2>/dev/null | grep '→' || echo "(ncu indisponible ou rien à jour — utiliser 'bunx npm-check-updates')"`

## Pré-requis (vérifier avant de toucher quoi que ce soit)

1. **Arbre git propre.** Si des changements traînent (voir contexte injecté), demande à l'utilisateur de committer/stash d'abord — la diff des dépendances doit rester isolée. Ne stash jamais son travail sans accord.
2. **Monorepo ?** Si la racine git est au-dessus du dossier courant (workspaces, plusieurs sous-projets), ne mets à jour QUE le `package.json` du projet courant et ne stage que ses fichiers au commit. Ne touche pas aux projets voisins.
3. **Le repo build et teste à l'état actuel.** Lance la gate de validation (§ Validation) une fois *avant* tout changement pour avoir une baseline verte. Si c'est déjà rouge, signale-le et arrête — on ne mélange pas un repo cassé avec une montée de version.

## Toolchain

Détecte et utilise l'outillage réel du repo (ne présume pas) :

- **Package manager** : `packageManager` dans `package.json`, sinon le lockfile (`bun.lock`→bun, `pnpm-lock.yaml`→pnpm, `package-lock.json`→npm, `yarn.lock`→yarn).
- **Install** : `bun install` / `pnpm install` / `npm install`. ⚠️ Pour bun, le prune prod est `--production` (ou `--omit=dev`) — `--no-dev` est **silencieusement ignoré**.
- **Validation** : si `vp` (Vite+) est présent → `vp check` (lint+fmt+typecheck) ; sinon les scripts du repo (`lint`, `typecheck`, `build`) ou la CLI framework (`astro check`, `svelte-check`, `tsc --noEmit`).
- **Tests** : exécute *tous* les runners présents (un repo peut avoir `bun test` ET `vitest run` — lance les deux).

## Procédure

### 1. Upgrade natif du framework (d'abord)

Si le framework expose un upgrade officiel, lance-le **avant** ncu — il aligne le core + ses intégrations sur des versions compatibles et applique les codemods :

| Framework | Commande |
|---|---|
| Astro | `bunx @astrojs/upgrade` (≈ `bun run upgrade` si le script existe) |
| Next.js | `bunx @next/codemod@latest upgrade latest` |
| Nuxt | `bunx nuxi upgrade` |
| SvelteKit | `bunx sv migrate` |
| Strapi | `bunx @strapi/upgrade latest` |

Ces outils sont parfois interactifs : lance-les non-interactivement si un flag existe, sinon préviens l'utilisateur qu'une confirmation TTY peut être requise. Après l'upgrade natif → **install + gate de validation complète**. Si rouge, lis la sortie, corrige (codemod manquant, breaking change), revalide. Commit `chore(deps): <framework> upgrade` une fois vert.

### 2. Énumérer le reste avec ncu, trier sûr vs majeur

- `ncu` (read-only) pour lister. Sépare en deux lots :
  - **Sûr** = patch/minor sur une même majeure ≥ 1.0 (`^1.2.x → ^1.5.x`).
  - **Majeur / risqué** = bump de majeure (`1.x → 2.0`) **ET** tout bump de `0.x` minor (`0.34 → 0.35`), car en semver `0.x` un minor peut casser.
- Annonce le tri à l'utilisateur avant d'appliquer.

### 3. Lot sûr — groupé

- `ncu -u --reject <liste des risqués>` puis install.
- **Gate de validation complète** (§ Validation). Si rouge, isole le coupable (réapplique paquet par paquet), répare ou exclus-le avec une note. Ne committe jamais un lot rouge.
- Commit `chore(deps): bump minor/patch deps` une fois vert.

### 4. Lot majeur — UNE dépendance à la fois

Pour chaque paquet majeur, dans cet ordre :

1. **Lire la doc de migration.** Utilise `context7` (`resolve-library-id` → `query-docs` sur "migration"/"breaking changes" + version cible) ou `WebFetch` sur le changelog/guide officiel. Pour plusieurs majeures, délègue la lecture à des subagents `docs-researcher` en parallèle (un par paquet) — ils retournent *uniquement* les breaking changes pertinents + l'effort de migration, pas le changelog brut.
2. **Vérifier l'usage réel** dans le code (`grep` des imports/API du paquet). Une majeure non utilisée, ou utilisée en type-only, est souvent triviale.
3. **Appliquer** (`ncu -u --filter <paquet>` + install) et exécuter les codemods éventuels documentés.
4. **Gate de validation complète.**
   - Vert → garde, commit `chore(deps): upgrade <paquet> v1→v2` (corps = breaking changes traités).
   - Rouge → applique les correctifs de migration *si* bornés et sûrs, revalide. Si la migration est lourde/incertaine → **revert ce paquet** (`git checkout package.json bun.lock && bun install`) et signale-le à l'utilisateur avec le lien de migration et l'effort estimé. On ne force pas une majeure cassante.

### 5. Validation — réelle, pas seulement le typecheck

Le typecheck et les tests unitaires prouvent la *correction du code*, pas que *l'app tourne*. La gate complète, dans l'ordre :

1. **Lint + fmt + typecheck** : `vp check` (ou équivalent). Ignore le bruit hors-périmètre (ex. `.claude/settings.local.json` non suivi).
2. **Tests unitaires** : tous les runners présents (`bun test`, `vitest run`, …). 0 fail.
3. **Build** : `vp build` / `astro build` / CLI framework. Doit finir « Complete ».
4. **Smoke runtime réel** : démarre le **vrai point d'entrée serveur**, pas un preview factice.
   - Astro + adapter node standalone : `astro preview` ne marche pas → lance `bun ./start.mjs` (ou `node ./dist/server/entry.mjs`) avec les env vars requises, puis `curl` les routes clés. Vérifie le **status** (< 500) *et* une sortie critique rendue (JSON-LD, balises SEO, contenu de la page) — pas seulement le code HTTP.
   - API/Strapi : démarre le serveur, hit un endpoint réel, inspecte le corps de réponse.
   - Si tu ne peux pas exercer le runtime (pas de serveur, creds manquantes), **dis-le explicitement** — ne déclare pas succès sur le seul typecheck.
5. **Docker** (si `Dockerfile` présent et que la montée touche le build/runtime) : `docker build` + boot conteneur + curl. Vérifie aussi que l'image runtime reste lean (pas de devDeps qui fuient).

### 6. Commit & rapport

- Commits **conventionnels**, scopés par étape (natif / mineures / chaque majeure) — ou un seul `chore(deps): update dependencies` si tout est passé d'un bloc sans incident. Mentionne explicitement les majeures dans le corps.
- **Pas de push** sauf demande explicite.
- Hooks staged (`vp`/lint-staged) : laisse-les tourner, ne les bypasse pas.

## Rapport final (concis, point par point)

- **Mineures/patch** : N paquets, lot validé ✅
- **Majeures** : pour chacune → version, verdict (gardée / revert), breaking changes traités, lien doc
- **Validation** : résultat de chaque gate (check / tests / build / smoke runtime / docker)
- **Reverts & risques restants** : ce qui n'a pas été monté et pourquoi
- **Commits créés** (hash + sujet), push : non (sauf demande)

## Principes non négociables

- Jamais `ncu -u` global aveugle suivi d'un commit sans validation.
- Une majeure = lire la doc avant, valider après. Pas d'exception.
- Valider = exercer l'app pour de vrai, pas juste compiler.
- Repo cassant après une majeure et migration non triviale → revert + rapport, pas de hack pour faire passer.
- Monorepo → périmètre strict au projet courant.
