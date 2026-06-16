---
description: Met à jour les dépendances du repo courant en autonomie (aucune question) — upgrade natif du framework, puis ncu (mineures groupées, majeures une par une avec lecture de la doc de migration), validation réelle derrière chaque étape, le tout commité sur une branche dédiée locale (ni push, ni PR) à merger quand tu veux.
allowed-tools: Bash(ls:*), Bash(grep:*), Bash(git status:*), Bash(git rev-parse:*), Bash(ncu:*)
---

Met à jour les dépendances du repo courant **avec prudence et validation réelle**. Jamais un `ncu -u` aveugle : on sépare le sûr du cassant, on lit la doc des majeures, et on prouve que ça marche avant de committer.

> **Contrat autonome.** Cette commande ne pose **aucune question** et n'attend **aucune action manuelle** — pas de `!`, pas de prompt TTY. Chaque point de décision est une règle automatique : soit *avancer sans risque*, soit *sauter + consigner au rapport*. Conçue pour tourner sans surveillance (routine Claude Code locale). Elle ne touche **jamais** la branche par défaut : tout le travail va sur une branche dédiée **locale** (ni push, ni PR) que tu revois et merges quand tu veux. En headless les permissions sont pré-accordées par le lanceur ; la commande, elle, ne réclame jamais d'intervention humaine.

## Contexte injecté

- Racine git : !`git rev-parse --show-toplevel 2>/dev/null || echo "(pas un repo git)"`
- Arbre propre ? : !`git status --short 2>/dev/null || echo "(n/a)"`
- Manifests : !`ls package.json bun.lock* package-lock.json pnpm-lock.* yarn.lock vite.config.* astro.config.* svelte.config.* next.config.* nuxt.config.* 2>/dev/null || echo "aucun"`
- Package manager : !`grep -m1 '"packageManager"' package.json 2>/dev/null || echo "(non déclaré — déduire du lockfile)"`
- Frameworks détectés : !`grep -oE '"(astro|next|nuxt|@sveltejs/kit|svelte|vue|@tanstack/react-start|@tanstack/start|react|react-dom|@strapi/strapi|strapi|@legendapp/state|better-auth|drizzle-orm)"' package.json 2>/dev/null | sort -u || echo "(aucun)"`
- Mises à jour disponibles : !`ncu 2>/dev/null | grep '→' || echo "(ncu indisponible ou rien à jour — utiliser 'bunx npm-check-updates')"`

## Pré-requis (règles automatiques, aucune question)

0. **Branche dédiée.** Crée/bascule sur `chore/deps-upgrade-<YYYY-MM-DD>` depuis le HEAD courant. Tout le travail y reste ; la branche par défaut n'est jamais modifiée.
1. **Arbre git propre.** Si de **vrais** changements non commités traînent (voir contexte injecté), **saute ce repo** et consigne-le au rapport — impossible d'isoler proprement la diff des deps. Ne stash jamais, ne commit jamais le travail en cours. **Exception bruit** : ignore les chemins outillage non suivis (`.claude/`, `.claude/settings.local.json`) — leur seule présence ne fait pas sauter le repo.
2. **Monorepo ?** Si la racine git est au-dessus du dossier courant (workspaces, plusieurs sous-projets), ne mets à jour QUE le `package.json` du projet courant et ne stage que ses fichiers au commit. Ne touche pas aux projets voisins.
3. **Baseline verte.** Lance la gate de validation (§ Validation) une fois *avant* tout changement. Si c'est déjà rouge à l'état actuel, **saute ce repo** et consigne-le — on ne mélange pas un repo cassé avec une montée de version.

## Toolchain

Détecte et utilise l'outillage réel du repo (ne présume pas) :

- **Package manager** (noté `<pm>`) : `packageManager` dans `package.json`, sinon le lockfile (`bun.lock`→bun, `pnpm-lock.yaml`→pnpm, `package-lock.json`→npm, `yarn.lock`→yarn).
- **Lockfile** (noté `<lock>`, pour les reverts) : `bun.lock` / `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` selon le PM détecté.
- **Runner one-shot** (noté `<dlx>`, pour les binaires d'upgrade) : bun→`bunx`, pnpm→`pnpm dlx`, npm→`npx`, yarn→`yarn dlx`.
- **Install** : `<pm> install`. ⚠️ Pour bun, le prune prod est `--production` (ou `--omit=dev`) — `--no-dev` est **silencieusement ignoré**.
- **Validation** : si `vp` (Vite+) est présent → `vp check` (lint+fmt+typecheck) ; sinon les scripts du repo (`lint`, `typecheck`, `build`) ou la CLI framework (`astro check`, `svelte-check`, `tsc --noEmit`).
- **Tests** : exécute *tous* les runners présents (un repo peut avoir `bun test` ET `vitest run` — lance les deux).

## Procédure

### 1. Upgrade natif du framework (d'abord)

Si le framework expose un upgrade officiel, lance-le **avant** ncu — il aligne le core + ses intégrations sur des versions compatibles et applique les codemods :

| Framework | Commande | Flag non-interactif |
|---|---|---|
| Astro | `<dlx> @astrojs/upgrade` (≈ `<pm> run upgrade` si le script existe) | — (interactif) |
| Next.js | `<dlx> @next/codemod@latest upgrade latest` | — (interactif) |
| Nuxt | `<dlx> nuxi upgrade` | `--force` |
| SvelteKit | `<dlx> sv migrate` | — (interactif) |
| Strapi | `<dlx> @strapi/upgrade latest` | `-y` |

⚠️ **Aucune interaction TTY** (contrat autonome). Pour chaque upgrade natif :

1. **Flag non-interactif disponible** (colonne ci-dessus, ou `CI=1`/`CI=true` que la plupart des CLI respectent) → utilise-le, lance, valide.
2. **Outil interactif-only, aucun moyen de le rendre silencieux** → **ne le lance pas**. Bascule ce framework dans le **lot majeur** (§4) : bump des paquets (`<framework>` + intégrations) via `ncu -u --filter`, codemods exécutés explicitement par nom (`<dlx> @next/codemod@latest <transform> . --force`, etc.), puis validation. Si aucun codemod non-interactif ne couvre la migration → **saute ce framework** et consigne-le (version cible + lien doc) au rapport.

Après l'upgrade natif → **install + gate de validation complète**. Si rouge, lis la sortie, corrige (codemod manquant, breaking change), revalide. Vert → commit `chore(deps): <framework> upgrade`. Toujours rouge / migration non bornée → **revert** (`git checkout package.json <lock> && <pm> install`) + consigne au rapport. Jamais de blocage en attente d'un humain.

### 2. Énumérer le reste avec ncu, trier sûr vs majeur

- `ncu` (read-only) pour lister. Sépare en deux lots :
  - **Sûr** = patch/minor sur une même majeure ≥ 1.0 (`^1.2.x → ^1.5.x`).
  - **Majeur / risqué** = bump de majeure (`1.x → 2.0`) **ET** tout bump de `0.x` minor (`0.34 → 0.35`), car en semver `0.x` un minor peut casser.
- Consigne le tri (sûr vs majeur) dans le rapport — sans attendre de validation.

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
   - Rouge → applique les correctifs de migration *si* bornés et sûrs, revalide. Si la migration est lourde/incertaine → **revert ce paquet** (`git checkout package.json <lock> && <pm> install`) et signale-le à l'utilisateur avec le lien de migration et l'effort estimé. On ne force pas une majeure cassante.

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

### 6. Commit (local, branche dédiée)

- Commits **conventionnels**, scopés par étape (natif / mineures / chaque majeure) — ou un seul `chore(deps): update dependencies` si tout est passé d'un bloc sans incident. Mentionne explicitement les majeures dans le corps.
- Hooks staged (`vp`/lint-staged) : laisse-les tourner, ne les bypasse pas.
- **Ni push, ni PR.** Les commits restent sur la branche `chore/deps-upgrade-<date>` locale — c'est ta surface de review. Jamais sur la branche par défaut, jamais de merge.
- **Rien à monter** (aucune mise à jour dispo, ou tout a été revert/sauté) → pas de branche fantôme : reviens sur la branche d'origine et supprime la branche dédiée vide. Consigne « rien à faire ».

## Rapport final (concis, point par point)

- **Mineures/patch** : N paquets, lot validé ✅
- **Majeures** : pour chacune → version, verdict (gardée / revert), breaking changes traités, lien doc
- **Validation** : résultat de chaque gate (check / tests / build / smoke runtime / docker)
- **Reverts & risques restants** : ce qui n'a pas été monté et pourquoi
- **Commits créés** (hash + sujet) sur la branche `chore/deps-upgrade-<date>` (locale, à merger quand tu veux)
- **Repos sautés** (arbre sale / baseline rouge / framework interactif) avec la raison

## Principes non négociables

- Jamais `ncu -u` global aveugle suivi d'un commit sans validation.
- Une majeure = lire la doc avant, valider après. Pas d'exception.
- Valider = exercer l'app pour de vrai, pas juste compiler.
- Repo cassant après une majeure et migration non triviale → revert + rapport, pas de hack pour faire passer.
- Monorepo → périmètre strict au projet courant.
- **Jamais bloquer en attente d'un humain** : pas d'étape interactive, on saute + consigne plutôt que d'attendre.
- **Jamais** la branche par défaut, **jamais** de merge : tout reste sur une branche dédiée locale, à toi de merger.
