---
description: Met à jour les dépendances du repo courant en autonomie (aucune question) — en monorepo, parcourt TOUS les sous-projets (front, back, packages) ; upgrade natif du framework, puis ncu (mineures groupées, majeures une par une avec lecture de la doc de migration), validation réelle (build + smoke runtime + Docker si présent) derrière chaque étape, le tout commité sur une branche dédiée locale (ni push, ni PR) à merger quand tu veux.
allowed-tools: Bash(ls:*), Bash(grep:*), Bash(find:*), Bash(git status:*), Bash(git rev-parse:*), Bash(ncu:*)
---

Met à jour les dépendances du repo courant **avec prudence et validation réelle**. Jamais un `ncu -u` aveugle : on sépare le sûr du cassant, on lit la doc des majeures, et on prouve que ça marche avant de committer.

> **Contrat autonome.** Cette commande ne pose **aucune question** et n'attend **aucune action manuelle** — pas de `!`, pas de prompt TTY. Chaque point de décision est une règle automatique : soit *avancer sans risque*, soit *sauter + consigner au rapport*. Conçue pour tourner sans surveillance (routine Claude Code locale). Elle ne touche **jamais** la branche par défaut : tout le travail va sur une branche dédiée **locale** (ni push, ni PR) que tu revois et merges quand tu veux. En headless les permissions sont pré-accordées par le lanceur ; la commande, elle, ne réclame jamais d'intervention humaine.

## Contexte injecté

- Racine git : !`git rev-parse --show-toplevel 2>/dev/null || echo "(pas un repo git)"`
- Arbre propre ? : !`git status --short 2>/dev/null || echo "(n/a)"`
- Manifests (racine) : !`ls package.json bun.lock* package-lock.json pnpm-lock.* yarn.lock vite.config.* astro.config.* svelte.config.* next.config.* nuxt.config.* 2>/dev/null || echo "aucun"`
- **Sous-projets** (tout `package.json` hors `node_modules`) : !`find . -name package.json -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/.output/*' 2>/dev/null | sort || echo "aucun"`
- Workspaces déclarés : !`grep -m1 -A6 '"workspaces"' package.json 2>/dev/null; cat pnpm-workspace.yaml 2>/dev/null || echo "(pas de workspaces déclarés — déduire des sous-projets)"`
- Dockerfiles : !`find . -iname 'Dockerfile*' -o -iname 'docker-compose*.y*ml' 2>/dev/null | grep -v node_modules | sort || echo "(aucun)"`
- Package manager : !`grep -m1 '"packageManager"' package.json 2>/dev/null || echo "(non déclaré — déduire du lockfile)"`
- Frameworks détectés : !`grep -rhoE '"(astro|next|nuxt|@sveltejs/kit|svelte|vue|@tanstack/react-start|@tanstack/start|react|react-dom|@strapi/strapi|strapi|@legendapp/state|better-auth|drizzle-orm)"' --include=package.json . 2>/dev/null | grep -v node_modules | sort -u || echo "(aucun)"`
- Mises à jour disponibles (racine) : !`ncu 2>/dev/null | grep '→' || echo "(ncu indisponible ou rien à jour — utiliser 'bunx npm-check-updates' ; en monorepo, relancer ncu dans chaque sous-projet)"`

## Pré-requis (règles automatiques, aucune question)

0. **Branche dédiée.** Crée/bascule sur `chore/deps-upgrade-<YYYY-MM-DD>` depuis le HEAD courant. Tout le travail y reste ; la branche par défaut n'est jamais modifiée.
1. **Arbre git propre.** Si de **vrais** changements non commités traînent (voir contexte injecté), **saute le projet concerné** et consigne-le au rapport — impossible d'isoler proprement la diff des deps. En monorepo, ne saute que le ou les sous-projets dont le chemin a des changements (un fichier sale dans `immo-front` ne bloque pas `immo-cms`) ; des changements sur de la config racine partagée (lockfile racine, `package.json` racine) font sauter la passe racine. Ne stash jamais, ne commit jamais le travail en cours. **Exception bruit** : ignore les chemins outillage non suivis (`.claude/`, `.claude/settings.local.json`) — leur seule présence ne fait sauter aucun projet.
2. **Monorepo = TOUS les sous-projets.** Énumère chaque projet à monter (voir contexte injecté « Sous-projets ») : la racine si elle a un `package.json` à elle, **plus chaque sous-projet** (front, back, `packages/*`, `apps/*`, ou dossiers nommés type `immo-front` / `immo-cms`). Un « projet » = un dossier avec son propre `package.json`. Traite-les **un par un**, dans l'ordre back → front quand l'un sert l'autre. Chaque projet a sa propre toolchain, sa propre gate de validation, son propre Dockerfile — détecte-les **dans le dossier du projet**, ne présume pas que c'est le même PM/framework que la racine. Commits scopés par projet (`chore(deps): bump immo-cms minor deps`), en ne stageant que les fichiers de ce projet. Ne saute un sous-projet que selon les règles 1 et 3 ci-dessous, appliquées **à ce sous-projet** — saute le projet fautif, pas tout le monorepo.
3. **Baseline verte (par projet).** Avant de toucher un projet, lance **sa** gate de validation (§ Validation) une fois. Si elle est déjà rouge à l'état actuel, **saute ce projet** et consigne-le — on ne mélange pas un projet cassé avec une montée de version. Les autres sous-projets continuent normalement.

## Toolchain

Détecte et utilise l'outillage réel **de chaque projet** (ne présume pas — un monorepo peut mélanger bun au front et npm au back) :

- **Package manager** (noté `<pm>`) : `packageManager` dans le `package.json` du projet, sinon le lockfile le plus proche (`bun.lock`→bun, `pnpm-lock.yaml`→pnpm, `package-lock.json`→npm, `yarn.lock`→yarn).
- **Lockfile** (noté `<lock>`, pour les reverts) : `bun.lock` / `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` selon le PM détecté.
- **Runner one-shot** (noté `<dlx>`, pour les binaires d'upgrade) : bun→`bunx`, pnpm→`pnpm dlx`, npm→`npx`, yarn→`yarn dlx`.
- **Install** : `<pm> install`. ⚠️ Pour bun, le prune prod est `--production` (ou `--omit=dev`) — `--no-dev` est **silencieusement ignoré**.
- **Install en monorepo** : repère si les deps sont hoistées à la racine. **Workspace partagé** (un seul lockfile racine, `node_modules` racine, champ `workspaces`/`pnpm-workspace.yaml`) → `ncu -u` dans le `package.json` du sous-projet, puis **un seul install à la racine** (`<pm> install` racine, ou `pnpm -F <pkg> install`) qui résout tout l'arbre. **Projets indépendants** (chacun son lockfile) → `ncu -u` + `<pm> install` **dans le dossier du projet**. Le revert d'un projet ne touche que **son** `package.json`/`<lock>`.
- **Validation** : si `vp` (Vite+) est présent → `vp check` (lint+fmt+typecheck) ; sinon les scripts du projet (`lint`, `typecheck`, `build`) ou la CLI framework (`astro check`, `svelte-check`, `tsc --noEmit`). Lance-la **depuis le dossier du projet** (ou `vp -F <pkg>` / `<pm> -F <pkg> run` si la toolchain est pilotée depuis la racine).
- **Tests** : exécute *tous* les runners présents dans le projet (un projet peut avoir `bun test` ET `vitest run` — lance les deux).

## Procédure

> **En monorepo, répète les étapes 1→6 pour CHAQUE sous-projet** (back d'abord s'il sert le front), depuis le dossier du projet. Un projet sauté (arbre sale / baseline rouge / framework interactif non bornable) ne bloque pas les autres. En mono-projet, c'est simplement une passe unique.

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
5. **Docker** — obligatoire dès qu'un `Dockerfile` couvre le projet monté et que la montée touche le build/runtime (deps de prod, runtime, moteur de build, version Node/Bun de l'image). Pour **chaque** Dockerfile concerné (un sous-projet peut avoir le sien) :
   - `docker build` (depuis le bon contexte/`-f`) doit réussir **sans cache** sur l'étape deps (`--no-cache` au moins sur le `install`) — sinon une lockfile périmée en couche cache masque la casse.
   - **Boot du conteneur** avec les env vars requises, puis `curl` les routes/endpoints clés : status < 500 **et** sortie critique réellement rendue (JSON, HTML, JSON-LD…), pas juste le code HTTP.
   - Si `docker-compose*.yml` orchestre plusieurs services (front + back + db), monte la stack et vérifie l'inter-service (le front joint le back).
   - Garde l'image **lean** : pas de devDeps qui fuient en runtime (prune prod), taille d'image stable ou meilleure.
   - **Docker indisponible** (daemon absent en headless) → ne déclare pas succès Docker : consigne « build Docker non vérifié (daemon absent) » au rapport. Ne committe pas une montée qui touche le runtime image en prétendant qu'elle est validée Docker.
   - Build ou boot Docker rouge → traite-le comme une gate rouge : corrige (souvent : régénérer le lockfile, aligner la version de base) et revalide, ou **revert** la montée fautive pour ce projet + consigne.

### 6. Commit (local, branche dédiée)

- **Une seule branche `chore/deps-upgrade-<date>` pour tout le monorepo.** Les commits y sont scopés **par projet ET par étape** (`chore(deps): bump immo-cms minor deps`, `chore(deps): upgrade immo-front astro v4→v5`), en ne stageant que les fichiers du projet concerné. En mono-projet, garde le scope d'étape simple.
- Commits **conventionnels** — ou un seul `chore(deps): update dependencies` par projet si tout y est passé d'un bloc sans incident. Mentionne explicitement les majeures dans le corps.
- Hooks staged (`vp`/lint-staged) : laisse-les tourner, ne les bypasse pas.
- **Ni push, ni PR.** Les commits restent sur la branche locale — c'est ta surface de review. Jamais sur la branche par défaut, jamais de merge.
- **Rien à monter nulle part** (aucune mise à jour dispo dans aucun projet, ou tout a été revert/sauté) → pas de branche fantôme : reviens sur la branche d'origine et supprime la branche dédiée vide. Consigne « rien à faire ».

## Rapport final (concis, point par point)

> En monorepo, structure le rapport **par sous-projet** (`immo-cms`, `immo-front`, racine…), chacun avec les rubriques ci-dessous, puis une synthèse globale en fin.

- **Mineures/patch** : N paquets, lot validé ✅
- **Majeures** : pour chacune → version, verdict (gardée / revert), breaking changes traités, lien doc
- **Validation** : résultat de chaque gate (check / tests / build / smoke runtime / **docker** : build + boot + curl, ou « non vérifié » + raison)
- **Reverts & risques restants** : ce qui n'a pas été monté et pourquoi
- **Commits créés** (hash + sujet) sur la branche `chore/deps-upgrade-<date>` (locale, à merger quand tu veux)
- **Projets/repos sautés** (arbre sale / baseline rouge / framework interactif) avec la raison

## Principes non négociables

- Jamais `ncu -u` global aveugle suivi d'un commit sans validation.
- Une majeure = lire la doc avant, valider après. Pas d'exception.
- Valider = exercer l'app pour de vrai, pas juste compiler.
- Repo cassant après une majeure et migration non triviale → revert + rapport, pas de hack pour faire passer.
- Monorepo → **tous les sous-projets**, un par un, chacun validé indépendamment (toolchain + gate + Docker propres au projet). Un projet sauté ne bloque pas les autres.
- Dockerfile concerné par la montée → build + boot + curl obligatoires ; jamais déclarer « validé Docker » sans l'avoir réellement buildé et démarré.
- **Jamais bloquer en attente d'un humain** : pas d'étape interactive, on saute + consigne plutôt que d'attendre.
- **Jamais** la branche par défaut, **jamais** de merge : tout reste sur une branche dédiée locale, à toi de merger.
