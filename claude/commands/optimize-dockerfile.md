---
description: Optimise le Dockerfile d'une app Bun + Nitro (TanStack Start) en image runtime minimale (mini-bun, bundle Nitro auto-suffisant, scripts de boot bundlés, zéro node_modules), avec vérification runtime avant commit.
---

Optimise le Dockerfile du repo courant pour produire l'image de prod la plus petite possible **sans rien casser**. Recette éprouvée sur ADZ : `963 MB → 412 MB → 42 MB`.

L'idée clé : le bundle Nitro (preset `bun`) est **auto-suffisant** — il n'externalise que `tslib`. Donc si on bundle aussi les scripts de boot, l'image runtime n'a **plus besoin de `node_modules`** du tout. On ne ship que `.output` + scripts bundlés + assets de migration sur `popwers/mini-bun` (~33 MB).

## Quand l'appliquer

- ✅ **App Bun + Nitro** : `packageManager` bun, `nitro` présent (directement ou via `@tanstack/react-start`), build → `.output/server/index.mjs`.
- ⚠️ **Pas Nitro / pas Bun** : la stratégie « zéro node_modules » ne tient pas telle quelle. Applique seulement le squelette multi-stage + mini-bun et **garde un node_modules prod** (Tier 2 ci-dessous). Ne force jamais le Tier 1 sans la vérif de l'étape B.

## Deux paliers

| Palier | Image runtime | Quand |
|--------|---------------|-------|
| **Tier 1 — zéro node_modules** | `.output` + scripts `.mjs` bundlés | le bundle n'externalise que `tslib` (cas Nitro/bun standard) |
| **Tier 2 — node_modules prod** | `.output` + `node_modules` (`--production`) | le bundle externalise d'autres deps, OU scripts non bundlables (require dynamique) |

Le Tier 1 est l'objectif. **On ne descend au Tier 2 que si l'étape B le prouve** — §10 : on ne devine pas, on vérifie et on signale.

## Procédure

### A. Détection & prérequis

1. **Confirme la stack** :
   ```sh
   grep -E '"packageManager"|"nitro"|react-start' package.json
   ls .output/server/index.mjs 2>/dev/null || bun run build
   ```
2. **Repère les scripts de boot** (migration, bootstrap/seed, create-admin…) lancés par l'entrypoint ou les scripts `package.json` :
   ```sh
   ls scripts/*.ts 2>/dev/null; grep -nE 'migrate|bootstrap|seed|create-admin' package.json
   ```
   Note leurs imports : tout ce qu'ils tirent (`drizzle-orm`, `postgres`, `better-auth`, `nanoid`, `dotenv`, `../src/lib/...`) sera inliné par `bun build`.

### B. Vérifier l'auto-suffisance du bundle (décide Tier 1 vs Tier 2)

3. **Qu'est-ce que Nitro a externalisé ?**
   ```sh
   ls .output/server/node_modules 2>/dev/null
   ```
   - **Seulement `tslib` (ou vide)** → Tier 1. Le serveur tourne sans `node_modules`.
   - **D'autres paquets** → ils ne sont pas bundlés ; reste en Tier 2 et copie `node_modules` prod.
4. **Confirme que les deps lourdes runtime sont bien inlinées** (ex. génération PDF, sharp, etc.). Repère les imports statiques côté serveur et vérifie leur présence :
   ```sh
   grep -rsl "PDFDocument\|@react-pdf\|sharp" src/ | head
   grep -rl "<dep>" .output/server/_libs 2>/dev/null
   ```
   Une dep à `require()` dynamique (résolu au runtime) ne sera PAS bundlée → Tier 2.

### C. Bundler les scripts de boot (Tier 1 uniquement)

5. **Teste le bundling en local** avant de toucher au Dockerfile (idempotent, vs DB de dev) :
   ```sh
   bun build scripts/migrate.ts   --target bun --outfile /tmp/ds/migrate.mjs
   bun build scripts/bootstrap.ts --target bun --outfile /tmp/ds/bootstrap.mjs
   DATABASE_URL='...dev...' bun /tmp/ds/migrate.mjs   # doit appliquer/no-op proprement
   ```
   Si un script crash au bundling ou au run (require dynamique, top-level await piégé) → ce script reste en `.ts` + Tier 2.
   - Pas de `--minify` : les scripts sont déjà minuscules (~200 Ko) ; minifier ajoute un risque pour un gain nul.
   - Sortie en `.mjs` : ESM sans ambiguïté, aucun `package.json` requis au runtime.

### D. Écrire le Dockerfile

6. **Template Tier 1** (zéro node_modules) — adapte les `COPY` aux assets réels (migrations Drizzle, etc.) :
   ```dockerfile
   # syntax=docker/dockerfile:1.7
   ARG BUN_VERSION=1.3.14

   # ---- deps : deps complètes (devDeps incluses) pour le build ----
   FROM oven/bun:${BUN_VERSION}-alpine AS deps
   WORKDIR /app
   COPY package.json bun.lock ./
   RUN --mount=type=cache,target=/root/.bun/install/cache,sharing=locked \
       bun install --frozen-lockfile

   # ---- build : bundle Nitro + scripts de boot autonomes ----
   FROM oven/bun:${BUN_VERSION}-alpine AS build
   WORKDIR /app
   ENV NODE_ENV=production NITRO_PRESET=bun
   COPY --from=deps /app/node_modules ./node_modules
   COPY . .
   RUN bun run build \
       && bun build scripts/migrate.ts   --target bun --outfile dist-scripts/migrate.mjs \
       && bun build scripts/bootstrap.ts --target bun --outfile dist-scripts/bootstrap.mjs

   # ---- runner : mini-bun (~33 MB), aucun node_modules ----
   FROM popwers/mini-bun:latest AS runner
   WORKDIR /home/bun/app
   ENV NODE_ENV=production PORT=3000 STORAGE_DIR=/home/bun/app/storage
   COPY --chown=bun:bun --from=build /app/.output ./.output
   COPY --chown=bun:bun --from=build /app/dist-scripts ./dist-scripts
   COPY --chown=bun:bun drizzle ./drizzle
   COPY --chown=bun:bun docker-entrypoint.sh ./
   RUN chmod +x docker-entrypoint.sh && mkdir -p storage && chown bun:bun storage
   USER bun
   EXPOSE 3000
   HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
       CMD ["bun","-e","fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/api/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"]
   ENTRYPOINT ["./docker-entrypoint.sh"]
   ```
   **Différence Tier 2** : ajoute un stage `prod-deps` (`bun install --frozen-lockfile --production` avec cache mount), copie `--from=prod-deps /app/node_modules ./node_modules` + `src/lib` (modules importés par les scripts `.ts`), et garde les scripts en `.ts` dans l'entrypoint.

7. **Entrypoint** `docker-entrypoint.sh` (migrate → bootstrap → serve ; `set -e` pour ne jamais servir sur une base non migrée) :
   ```sh
   #!/bin/sh
   set -e
   bun dist-scripts/migrate.mjs        # Tier 2 : bun scripts/migrate.ts
   bun dist-scripts/bootstrap.mjs      # Tier 2 : bun scripts/bootstrap.ts
   exec bun .output/server/index.mjs
   ```
   Si un script de boot affiche un chemin (ex. message « créez un admin avec … »), rends-le **agnostique du chemin** (`dist-scripts/*.mjs` en prod ≠ `scripts/*.ts` en dev) ou pointe vers la doc de déploiement.

### E. .dockerignore

8. **Allège le contexte de build** — exclus tout ce qui ne sert ni au build ni au runtime :
   ```
   node_modules
   .output
   .tanstack
   .nitro
   dist
   dist-scripts
   .git
   .env
   .env.*
   !.env.example
   .vscode .idea .cursor .claude
   storage
   **/__tests__
   *.test.ts
   *.test.tsx
   ```
   Ajoute `dist-scripts` au `.gitignore` aussi (artefact de build).

### F. Build + VÉRIFICATION RUNTIME (l'étape non négociable)

9. **Build + mesure** :
   ```sh
   docker build -t <app>:opt .
   docker images <app> --format '{{.Repository}}:{{.Tag}}  {{.Size}}'
   ```
10. **Run en conteneur contre la DB de dev** et exerce **tous** les chemins runtime, pas juste `/health` :
    ```sh
    docker run -d --name opt-test -p 3999:3000 \
      -e DATABASE_URL='postgres://...@host.docker.internal:5433/...' \
      -e BETTER_AUTH_SECRET="$(openssl rand -base64 32)" \
      -e APP_URL='http://localhost:3999' <app>:opt
    docker logs opt-test            # migrate → bootstrap → Listening
    curl -fsS localhost:3999/api/health
    # + login (cookie jar) + une route qui tire les deps lourdes (PDF, image, etc.)
    ```
    C'est ce test qui valide « passe en prod sans souci » : une dep externalisée par erreur ne pète **pas** au boot, mais à la première requête qui l'utilise. Si une route 500 avec `ERR_MODULE_NOT_FOUND` → repasse en Tier 2.
11. **Nettoie** : `docker rm -f opt-test`, supprime le volume/user de test, restaure l'état de la DB de dev.

### G. Commit (via `cz` / `ga`)

12. `perf(docker): ship a minimal runtime image (<avant> -> <après>)` — Dockerfile + entrypoint + .dockerignore + .gitignore + doc de déploiement.

## Garde-fous

- **Jamais de Tier 1 sans l'étape B + F.** L'auto-suffisance se prouve, ne se suppose pas. Une dep à `require()` dynamique passe le boot et casse en prod.
- **Épingle la version** : `oven/bun:${BUN_VERSION}-alpine` côté build doit matcher le bun de mini-bun (musl). Pour figer le runtime, `popwers/mini-bun:v${BUN_VERSION}` au lieu de `:latest`.
- **`USER bun` + `--chown=bun:bun`** sur tous les `COPY`, et pré-crée le dossier de stockage (`mkdir -p storage && chown bun:bun storage`) — un volume monté sous un user non-root échoue sinon.
- **Chemin de stockage** : sous mini-bun le workdir est `/home/bun/app`, donc `STORAGE_DIR=/home/bun/app/storage` (≠ `/app/storage`). Mets à jour la doc de déploiement et le `-v` du `docker run`.
- **`alpine` pour les stages de build** : même ABI (musl) que mini-bun. Builder en debian/glibc puis runner alpine peut casser une dep native.
- **Image sans node_modules = pas de script Node ad-hoc** dans le conteneur. Bundle les scripts d'ops dont l'opérateur a besoin (ex. `create-admin`) et documente `docker exec … bun dist-scripts/<script>.mjs`.

## Format attendu en sortie

- Stack détectée + palier retenu (Tier 1 / Tier 2) **avec la preuve** (sortie de `ls .output/server/node_modules`).
- Tailles avant / après.
- Scripts de boot bundlés (liste) ou raison du fallback Tier 2.
- Matrice de vérif runtime : boot, health, auth, + chaque route lourde testée → code HTTP / résultat.
- Fichiers touchés (Dockerfile, entrypoint, .dockerignore, .gitignore, doc).
- Compromis résiduel (si applicable).

Pas de filler. Procède.
