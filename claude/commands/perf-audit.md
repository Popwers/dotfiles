---
description: Audit perf du repo (render-first-auth, optimistic mutations, asset loading) et applique les fixes sans casser le build.
---

Audit performance du repo courant. Identifie les écarts sur les trois axes ci-dessous et applique les fixes — sans toucher au runtime métier.

## Pré-requis

- Stack frontale (React, Astro, TanStack Start, SvelteKit, ou équivalent). Sinon skip avec une note.
- Le repo build (`vp build` ou la CLI framework). Sinon, signale-le et reste en audit-only.

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

## Format de sortie

Pour chaque axe :
1. **Status** : PASS / PARTIAL / FAIL / SKIP
2. **Findings** : `fichier:ligne` pour chaque écart
3. **Action** : diff résumé du fix appliqué, ou patch recommandé si invasif

À la fin :
- **Avant / après** : taille bundle + nombre de requêtes au premier paint (si `vp build` ou équivalent fonctionne).
- **Commits** suggérés (un par axe touché), via `cz` ou `ga`.

## Garde-fous

- Pas de refactor du runtime métier — uniquement boot order, mutation wiring, et asset loading.
- Si un fix demande >20 lignes de refactor applicatif sur un même endroit, surface-le en reco — ne l'applique pas.
- Monorepo : audite chaque package séparément, résume en tableau.

Procède.
