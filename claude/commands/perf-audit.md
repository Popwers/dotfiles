---
description: Audit the current repo against the Linear performance playbook (esnext target, per-package chunks, modulePreload, animation tokens, render-first-auth) and apply fixes.
---

Audit performance du repo courant contre le **Linear playbook** (https://performance.dev/how-is-linear-so-fast-a-technical-breakdown). Identifie les écarts et applique les fixes — sans casser le build.

## Pré-requis

- Repo Vite+ (sinon, lance `/migrate-vite` d'abord).
- Stack frontale présente (React, Astro, Tanstack Start, ou équivalent). Sinon skip avec une note.

## Audit en 5 axes

### 1. Build target & bundling (vite.config.ts)

Vérifie dans `vite.config.ts` :

- [ ] `build.target: "esnext"` — pas de polyfills ES5, pas de nomodule fallback. Bundle ~50% plus léger.
- [ ] `build.modulePreload.polyfill: false` — confiance dans le `<link rel="modulepreload">` natif (tous les navigateurs >= 2022).
- [ ] `build.rollupOptions.output.manualChunks` avec stratégie **par package** (un chunk par dep top-level >~3 KB). Cache invalidation indépendante entre deploys.

Si absents, ajoute le bloc `build:` complet en t'inspirant du gist de référence :
```
curl -fsSL https://gist.githubusercontent.com/Popwers/e112d96aea101e5aa35311048644d9cf/raw/vite.config.ts | grep -A 25 'build:'
```

### 2. Animation tokens (CSS)

Cherche `transition`, `animation-duration`, `--speed-` dans le repo.

- [ ] Existe un fichier de tokens (`tokens.css`, `app.css`, `globals.css`) avec les 4 tokens `--speed-*` ? Sinon, propose le bloc :
  ```css
  --speed-highlightFadeIn: 0s;
  --speed-quickTransition: 0.1s;
  --speed-regularTransition: 0.25s;
  --speed-slowTransition: 0.35s;
  ```
- [ ] Aucune transition > 350 ms en dehors d'animations décoratives explicitement nommées.
- [ ] Aucun `transition: all` (interdit — toujours nommer la prop).
- [ ] Animations sur `transform` / `opacity` uniquement. Flag tout `transition: width|height|top|left|margin|padding` (force layout reflow).

### 3. Render-first-auth (pour apps avec login)

Si le repo a un flow d'auth (BetterAuth, NextAuth, Tanstack auth, custom JWT) :

- [ ] Le premier paint ne bloque pas sur `fetchUser()` / `getSession()`.
- [ ] Un marker localStorage (ou cookie léger) détermine si on render le shell cached avant validation.
- [ ] Le 401 redirect est async, pas bloquant.

Si non, propose un patch du `root.tsx` / `+layout.svelte` / équivalent.

### 4. Optimistic mutations

Si TanStack Query, SWR, ou Legend State sont présents :

- [ ] Les mutations critiques (update title, toggle status, etc.) utilisent `optimisticUpdate` / `onMutate`.
- [ ] Pas de spinner > 100 ms pour des actions locales.
- [ ] Rollback explicite sur erreur serveur.

### 5. Asset loading

- [ ] Fonts : variables (un seul fichier woff2 pour toute l'axis weight) avec `font-display: swap` et `<link rel="preload">` + `crossorigin="anonymous"`.
- [ ] Pas de Google Fonts en runtime (self-host).
- [ ] Images critiques (above-the-fold) en `<img loading="eager" fetchpriority="high">`, le reste en `loading="lazy"`.
- [ ] Service worker pour précache des assets hashés (optionnel, mais bonus si app installable).

## Format de sortie

Pour chaque axe :
1. **Status** (PASS / PARTIAL / FAIL / SKIP)
2. **Findings** (fichier:ligne pour chaque écart)
3. **Fix appliqué** (diff résumé) ou **Fix recommandé** (si invasif)

À la fin :
- **Avant / après** : taille du bundle (`vp build && du -sh dist/`), nombre de chunks, taille du chunk principal.
- **Commits** suggérés (un par axe touché), via `cz` ou `ga`.

## Garde-fous

- Ne touche **pas** au runtime metier — uniquement build config, CSS tokens, et patterns de loading.
- Si un fix demande de refactorer du code applicatif (>20 lignes), surface-le en recommandation, ne l'applique pas.
- Si le repo est un monorepo, audite chaque package séparément et résume en tableau.
- Bench réel avant/après uniquement si le repo a un `vp build` qui marche.

Procède.
