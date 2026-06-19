---
description: Audit perf du repo (render-first-auth, mutations optimistes, asset loading, bundler, rendering granulaire, prerendering/SSG, prefetch & données) et applique les fixes sans casser le build.
allowed-tools: Bash(ls:*), Bash(grep:*)
---

Audit performance du repo courant. Identifie les écarts sur les axes ci-dessous et applique les fixes — sans toucher au runtime métier.

## Contexte injecté

- Manifests : !`ls package.json bun.lock* vite.config.* astro.config.* svelte.config.* next.config.* 2>/dev/null || echo "aucun"`
- Frameworks détectés : !`grep -oE '"(react|react-dom|astro|@tanstack/react-start|@sveltejs/kit|svelte|next|@legendapp/state|@tanstack/react-query|swr|motion|better-auth|next-auth)"' package.json 2>/dev/null | sort -u`

## Pré-requis

- Stack frontale (React, Astro, TanStack Start, SvelteKit, ou équivalent — voir contexte injecté). Sinon skip avec une note.
- Le repo build (`vp build` ou la CLI framework). Sinon, signale-le et reste en audit-only.

## Délégation

- **Scan** : lance les subagents read-only **en parallèle dans un seul message** via le Agent tool (`repo-explorer`, un par axe ou par paire d'axes proches). Chacun retourne `fichier:ligne — constat`, pas d'extraits longs.
- **Fixes** : les fixes ponctuels s'appliquent dans le contexte principal. Quand un axe entier demande correction (ex. bundler config + vendoring, conversion d'un lot de mutations), délègue à `performance-optimizer` avec un scope de fichiers explicite et les garde-fous ci-dessous.

## Axes d'audit

### 1. Render-first-auth (apps avec login)

Le premier paint **ne doit jamais bloquer** sur un appel réseau. Un marker local décide si on render le shell cached avant d'appeler le réseau.

Si le repo a un flow d'auth (BetterAuth, NextAuth, TanStack auth, JWT custom) :

- [ ] Détection synchrone d'un marker local (`localStorage`, IndexedDB key, ou cookie hint) avant le premier render.
- [ ] Shell + layout cached rendus immédiatement quand le marker existe (theme, sidebar, dernière route, derniers tokens UI).
- [ ] Validation du token en background — déclenchée **après** la première frame, pas avant.
- [ ] Redirect `401` async, jamais bloquant. L'utilisateur voit le shell puis le redirect, jamais un full-screen spinner d'auth.
- [ ] Aucun `await fetchUser()` / `await getSession()` au-dessus du premier `<Suspense>` / `+layout` / `root.tsx`.

Si absent, propose un patch du root (`root.tsx`, `+layout.svelte`, `app/layout.tsx`, `src/main.tsx`) avec le pattern marker → shell → background-validate → async-redirect.

### 2. Optimistic mutations

Si TanStack Query, SWR, Legend State, ou une couche de mutation custom sont présents :

- [ ] Toutes les mutations à feedback immédiat (toggle, rename, reorder, status change, like) utilisent `onMutate` / `optimisticUpdate` / écriture locale avant le réseau.
- [ ] Aucun spinner pour les actions locales courtes. Si un état "saving" est nécessaire, il est inline (subtil), pas bloquant.
- [ ] Rollback explicite sur erreur serveur — l'état local revient à la valeur pré-mutation et un toast surface l'échec.
- [ ] Pas de `await mutate()` qui bloque la fermeture d'un dialog ou la navigation. La nav part en parallèle de la requête.

Si des mutations critiques ne sont pas optimistes, liste les fichiers et propose la conversion (sans appliquer si >20 lignes par mutation — surface-le en reco).

### 3. Asset loading

- [ ] **Fonts** : variables (un seul woff2 pour tout l'axis weight), `font-display: swap`, `<link rel="preload">` + `crossorigin="anonymous"` sur les fonts above-the-fold.
- [ ] Aucune Google Fonts en runtime — self-host (via `@fontsource-variable/*` ou copie locale).
- [ ] **Images critiques** (above-the-fold, LCP candidate) : `<img loading="eager" fetchpriority="high" decoding="async">` + dimensions explicites pour éviter CLS.
- [ ] Reste des images : `loading="lazy"` + dimensions explicites.
- [ ] Pas de `<img>` non dimensionnée dans un layout fluide (CLS garanti).
- [ ] Icônes : sprite SVG ou composants inline, pas de requête par icône.
- [ ] Service worker pour précache des assets hashés (bonus si app installable / offline-friendly).
- [ ] **Critical CSS inliné** dans `<head>` (shell, theme tokens) — pas de stylesheet externe bloquante avant le premier paint.
- [ ] **Boot script inliné** (lecture `localStorage`, theme, marker auth) avant que les bundles JS soient parsés.
- [ ] **Modulepreload + `crossorigin`** sur les chunks critiques dans `<head>` pour paralléliser les downloads.
- [ ] **Cache HTTP & CDN** : assets hashés en `Cache-Control: public, max-age=31536000, immutable` ; pages prérenderées en `stale-while-revalidate` ; compression Brotli (fallback gzip) active ; `<link rel="preconnect">` (+ `dns-prefetch` fallback) vers l'origine API et le CDN de fonts above-the-fold.
- [ ] **Scripts tiers** (analytics, widgets, tags) en `async`/`defer` ou déportés (Partytown / web worker) — jamais un `<script>` bloquant dans le `<head>`.

### 4. Build & bundler config (Linear-style)

- [ ] `target: "esnext"` dans la config Vite/build — aucune transpile ES5, aucun polyfill legacy.
- [ ] `modulePreload: { polyfill: false }` — cibles modernes, pas de polyfill de préchargement legacy.
- [ ] **Per-package vendoring** : chaque dépendance npm >~3KB a son propre chunk (`manualChunks` par package) pour cache invalidation indépendante.
  - **Client-only / TanStack Start** : `manualChunks` générique par package OK (`vendor-${pkg}` pour tout `node_modules`).
  - **⚠️ Astro SSR** : le générique par package **compile mais casse le serveur au boot** (`ReferenceError: Cannot access '_getEnv' before initialization` — TDZ `astro:env` entre `vendor-astro`/`vendor-astrojs`). **Exclure `astro/` et `@astrojs/*` du split** (les garder dans le chunk par défaut), le reste en per-package. Toujours **boot-tester le serveur** après (build vert ≠ serveur qui démarre — cf. Garde-fous).
- [ ] Tree-shaking agressif activé, dead code éliminé (vérifier qu'aucune lib n'est importée en barrel-import qui défait le shaking).
- [ ] Code splitting route-level — un chunk par route, chargé on-demand (pas un bundle monolithique).

### 5. Rendering granulaire (apps avec state lourd)

- [ ] **Observables par propriété**, pas par modèle — Legend State / MobX : une mutation d'un champ ne re-render que les cellules qui le lisent, pas la liste entière.
- [ ] Liste de N items + mutation locale = N petits re-renders ciblés, jamais un re-render global de la liste.
- [ ] **Lazy hydration** des collections lourdes (Issues, Comments, ce qui équivaut chez nous) — chargées à la demande, pas au boot.
- [ ] **Animations compositor-only** : préférer `transform` / `opacity` à `width`/`height`/`top`/`left` (qui déclenchent layout/paint). Avec **Motion** : privilégier `x`, `y`, `scale`, `rotate`, `opacity`. Éviter le prop `layout` sur des listes longues ou des éléments above-the-fold — il déclenche du reflow (acceptable ponctuellement, pas en boucle).
- [ ] Durées 100-250ms (sous le seuil de perception 300ms). Asymétrie OK : apparition instantanée, fade-out 150ms pour popovers. Avec Motion, des `easing` custom courts (`[0.22, 1, 0.36, 1]` style) > durées longues.
- [ ] **Command palette local** si présent : recherche dans le store client (Legend State / IndexedDB), pas de requête serveur par frappe.

### 6. Prerendering / SSG / streaming

Le rendu le moins cher est celui qui n'a pas lieu à la requête. Tout ce qui est statique ou cache-friendly doit être prérenderé au build ; le reste doit streamer, jamais bloquer le TTFB.

Selon le framework détecté :

- **TanStack Start** :
  - [ ] `prerender: { enabled: true, crawlLinks: true }` dans le plugin `tanstackStart()` de `vite.config.*` — les routes statiques (landing, docs, marketing, pages légales) émises en HTML au build.
  - [ ] `filter` pour exclure explicitement les routes authentifiées / dynamiques du crawl, plutôt que de les laisser échouer (`failOnError` est `true` par défaut).
  - [ ] Activer le prerender **boote le serveur au build** (le plugin lance `vite preview`) : prévoir les env de build requis (ex. `SESSION_SECRET` factice) et, en Docker, binder `preview: { host: '127.0.0.1' }` (sinon `localhost`→`::1` → ConnectionRefused dans le sandbox).
  - [ ] Routes purement client (dashboard derrière auth) : `ssr: false` sur la route plutôt qu'un SSR runtime inutile qui alourdit le TTFB.
  - [ ] Route paramétrée (`/users/$id`) jamais prérenderée sans entrée `pages` explicite ou lien crawlé — sinon skip silencieux à surfacer.
- **Astro** :
  - [ ] Static par défaut (`output: 'static'`) ; passer en `server`/`hybrid` uniquement pour les routes qui en ont besoin, `export const prerender = true` sur tout le reste.
  - [ ] Contenu éditorial via **content collections** (build-time), pas de fetch runtime pour des données qui ne varient pas par requête.
  - [ ] `client:visible` / `client:idle` plutôt que `client:load` pour les îlots sous la ligne de flottaison.
- **SvelteKit** : `export const prerender = true` sur les routes statiques + `adapter-static` (ou `prerender.entries` pour les routes non liées).
- **Next** : `generateStaticParams` pour les routes dynamiques connues, `export const dynamic = 'force-static'` quand applicable, PPR pour le mix statique/dynamique.
- **Toutes stacks** — routes non prérenderables : shell + above-the-fold streament immédiatement (Suspense streaming, `defer`/`Await` TanStack, RSC), les données lentes arrivent après. Jamais un `await` data-fetch qui retient le document complet.

Si le repo sert en SSR runtime ce qui est déjà statique, ou laisse des landing/docs en client-render, propose la bascule prerender (config + flag par route). Ne convertis JAMAIS une route authentifiée en statique — surface-le en reco si ambigu.

### 7. Prefetch & cascades de données

La donnée doit arriver avant le clic, et en parallèle — jamais en chaîne. Cible les loaders, le préchargement à l'intention, et les waterfalls réseau.

- [ ] **Préchargement à l'intention** : navigation préchargée sur hover/focus/viewport. TanStack Router → `defaultPreload: 'intent'` (+ `defaultPreloadStaleTime`) ; `<Link prefetch>` côté Next/Astro pour les liens above-the-fold. **Anti-pattern fréquent** : `defaultPreloadStaleTime: 0` annule le bénéfice de l'intent-preload (donnée jetée aussitôt préchargée) → `30_000`.
- [ ] **Loaders parallèles, pas séquentiels** : les données d'une route partent en même temps, jamais `await a()` puis `await b()` quand b ne dépend pas de a. Repérer les waterfalls (un fetch qui attend le résultat d'un fetch parent sans dépendance réelle).
- [ ] **Pas de waterfall client après le mount** : la donnée critique est chargée par le loader de route (serveur/router), pas par un `useEffect(() => fetch())` qui ne part qu'après l'hydratation.
- [ ] **Dédup & cache des requêtes** : une même clé de données n'est pas fetchée N fois sur un paint (TanStack Query `staleTime` correct, Router loader deduping, pas de fetch dupliqué entre layout et page).
- [ ] **Pagination / infinite** : `prefetchNextPage` au survol du dernier item visible, pas un spinner plein écran à chaque page.

Si des données critiques arrivent en cascade ou via `useEffect` post-mount, liste les fichiers et propose le passage en loader de route (sans appliquer si le refactor dépasse 20 lignes par route — surface en reco).

## Format de sortie

**Tout le rapport est en français. Sois bref — pas de paragraphes, pas de redite des critères.**

### 1. Tableau récap (toujours en premier)

Une ligne par axe. Pas de détail ici, juste le scan.

| Axe | Statut | Écarts | Fixés | Reste |
|-----|--------|--------|-------|-------|
| Render-first-auth | ✅/⚠️/❌/— | 0 | 0 | 0 |
| Mutations optimistes | … | … | … | … |
| Asset loading | … | … | … | … |
| Build & bundler | … | … | … | … |
| Rendering granulaire | … | … | … | … |
| Prerendering / SSG | … | … | … | … |
| Prefetch & données | … | … | … | … |

Légende statut : ✅ PASS · ⚠️ PARTIAL · ❌ FAIL · — SKIP.

### 2. Détails (uniquement si écarts)

Pour chaque axe ⚠️/❌, une sous-section ultra-courte :

```
### Axe N — <nom>
- <fichier:ligne> — <constat en 1 ligne>  → fixé / reco
```

Pas de citation de code, pas de re-explication du critère. Si fix appliqué, mentionne le fichier touché, c'est tout.

### 3. Bundle (si build dispo)

Une ligne : `Bundle gzip : <avant> → <après> · Requêtes 1er paint : <avant> → <après>`. Sinon : `Build indisponible — audit-only`.

### 4. Recommandations à exécuter (toujours en dernier)

Liste numérotée des actions **non appliquées** que l'utilisateur doit lancer lui-même. Une ligne par reco, format :

```
1. <action impérative courte> — <fichier ou commande> — <impact attendu>
```

Si rien à exécuter : `Aucune reco — tout est appliqué.`

### 5. Commits suggérés

Une ligne par axe touché, format `cz`/`ga` prêt à coller. Skip si aucun fix appliqué.

## Garde-fous

- Pas de refactor du runtime métier — uniquement boot order, mutation wiring, asset loading, bundler config, render strategy, data wiring et animation primitives.
- Si un fix demande >20 lignes de refactor applicatif sur un même endroit, surface-le en reco — ne l'applique pas.
- Migration vers observables granulaires (axe 5) : ne JAMAIS l'appliquer en masse — surface en reco avec liste des composants impactés.
- Prerendering (axe 6) : ne JAMAIS convertir une route authentifiée ou data-dynamique en statique — la bascule prerender ne s'applique qu'aux routes sûres (landing, docs, légal) ; le reste en reco.
- Passage en loader de route (axe 7) : si le refactor dépasse 20 lignes par route, surface en reco — ne l'applique pas.
- **Validation SSR = build + boot.** Toute modif de chunking/bundler/render-strategy sur une app SSR (Astro, TanStack Start, Next…) se valide en **démarrant le serveur buildé** (`node ./dist/server/entry.mjs` ou l'image Docker) + un `curl` sur une route — pas seulement par un build vert. Certains bugs (TDZ de chunking) ne pètent qu'au runtime.
- **Changement de deps = resync du lockfile.** Tout fix qui ajoute/retire un package (dep inutilisée retirée, self-host de fonts via `@fontsource-*`) relance l'install (`vp install` / `bun install`) pour synchroniser le lockfile — sinon le build prod `--frozen-lockfile` (Docker/Coolify) échoue.
- Monorepo : audite chaque package séparément, résume en tableau.

Procède.
