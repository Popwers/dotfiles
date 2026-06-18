---
description: Optimise le Dockerfile du repo en image runtime minimale — multi-stage, base adaptée au runtime, Tier 1/2 selon l'auto-suffisance de l'artefact — avec vérification runtime avant commit.
allowed-tools: Bash(ls:*), Bash(grep:*)
---

Optimise le Dockerfile du repo courant pour produire l'image de prod la plus petite possible **sans rien casser**. La recette est **générale** — elle vaut pour Node, Bun, Deno, Go, Rust, Python, ou un front statique. Le principe directeur ne change pas d'une stack à l'autre ; seuls l'artefact de build et la base runtime changent.

> L'exemple de référence (annexe) est une app **Bun + Nitro (TanStack Start)** : `963 MB → 412 MB → 42 MB`. Réutilise-le tel quel si la stack correspond, sinon applique les principes ci-dessous à ta stack.

## Le principe (toutes stacks)

1. **Multi-stage.** Les outils de build (compilateur, devDeps, cache) ne doivent **jamais** atteindre l'image finale. Un stage `build` produit l'artefact ; un stage `runner` ne copie que cet artefact.
2. **Base runtime minimale**, adaptée au runtime (voir la table plus bas). Distroless / alpine / slim / scratch selon le cas — jamais l'image « full » qui a servi à builder.
3. **Ne ship que ce qui tourne en prod.** L'artefact de build + ce dont il a *réellement* besoin au runtime. Pas de sources, pas de devDeps, pas de caches, pas de tests.
4. **Drop les dépendances quand l'artefact est auto-suffisant.** C'est le plus gros gain : un binaire (Go/Rust), un bundle qui inline ses deps (esbuild/Rollup/ncc/Nitro), un `pyinstaller`… n'a **plus besoin** du gestionnaire de paquets ni de `node_modules`/`venv`. → **Tier 1**. Sinon on garde les deps de prod seulement → **Tier 2**.
5. **Cache de layers + cache mounts.** Copie `manifest + lockfile` *avant* le reste pour que `install` soit caché tant que les deps ne bougent pas ; monte le cache du gestionnaire (`--mount=type=cache`).
6. **Non-root, volumes, version, ABI.** `USER` non-root + `--chown` ; pré-crée les dossiers écrits (volumes montés) ; épingle les versions de base ; garde la **même ABI** entre build et runtime (musl alpine vs glibc debian — une dep native compilée sur l'un casse sur l'autre).
7. **Vérif runtime, pas juste boot.** Une dep oubliée ne pète pas au démarrage mais à la **première requête** qui l'utilise. On exerce les chemins lourds, pas seulement `/health`.

## Choix du palier (décision, indépendante de la stack)

| Palier | Image runtime | Quand |
|--------|---------------|-------|
| **Tier 1 — artefact auto-suffisant** | base minimale + artefact seul | le build produit un livrable autonome (binaire unique, bundle qui inline ses deps) |
| **Tier 2 — artefact + deps runtime** | base minimale + deps de prod (`--production` / `--frozen --omit=dev`) | le livrable garde des deps externes (require/import dynamique, deps natives non bundlables) |

Le Tier 1 est l'objectif. **On ne descend au Tier 2 que si l'étape B le prouve** — on ne devine pas l'auto-suffisance, on la vérifie et on signale le fallback.

## Procédure générique

### A. Détecter la stack & le runtime

Contexte pré-injecté à l'invocation :

- Manifests : !`ls package.json bun.lock* go.mod Cargo.toml pyproject.toml requirements.txt 2>/dev/null || echo "aucun"`
- Docker existant : !`ls Dockerfile* .dockerignore docker-entrypoint.sh 2>/dev/null || echo "aucun"`
- Package manager & build : !`grep -E '"packageManager"|"build"' package.json 2>/dev/null || echo "n/a"`

À partir de ça, identifie : runtime (node/bun/deno/go/rust/python/statique), gestionnaire de paquets, commande de build, et le **chemin de l'artefact** produit (`.output/`, `dist/`, `build/`, un binaire, etc.).

### B. Prouver l'auto-suffisance de l'artefact (décide Tier 1 vs Tier 2)
- **Binaire compilé** (Go/Rust) → Tier 1 d'office ; la seule question est `scratch` vs `distroless/static` (certif TLS, timezone).
- **Bundle JS** (esbuild/Rollup/ncc/Nitro/webpack `output`) → inspecte ce que le bundle laisse externe :
  ```sh
  # Nitro/bun : ce qui reste hors-bundle
  ls .output/server/node_modules 2>/dev/null
  # bundle générique : les require/import non résolus à build-time
  grep -rEl "require\(|import\(" dist/ build/ 2>/dev/null | head
  ```
  Vide / quasi vide → Tier 1. Des paquets présents → Tier 2 (copie les deps de prod).
- **Scripts d'ops** (migration, seed, create-admin…) lancés par l'entrypoint : tente de les bundler aussi (`bun build`, `ncc build`, `esbuild --bundle`). Un script à `require()` dynamique ne bundle pas → Tier 2 pour lui.

### C. Construire l'artefact minimal
- Lance le build de prod. Pour Tier 1, bundle aussi les scripts de boot en livrables autonomes.
- Pas de `--minify` sur de petits scripts d'ops : gain nul, risque non nul.

### D. Écrire le Dockerfile multi-stage
Structure constante quelle que soit la stack : `deps` (install caché) → `build` (artefact) → `runner` (base minimale, copie l'artefact seul en Tier 1, + deps prod en Tier 2). Choisis la base runtime :

| Runtime | Base runtime minimale |
|---------|------------------------|
| Node | `gcr.io/distroless/nodejs22` (Tier 1 bundle) · `node:22-slim` / `node:22-alpine` (Tier 2) |
| Bun | `popwers/mini-bun` (~33 MB) · `oven/bun:<v>-alpine` |
| Deno | `denoland/deno:bin` sur `distroless` · `denoland/deno:alpine` |
| Go / Rust | `scratch` · `gcr.io/distroless/static` (TLS/CA) |
| Python | `gcr.io/distroless/python3` · `python:3.x-slim` |
| Front statique | `nginx:alpine` · `caddy:alpine` · `scratch` + binaire serveur |

> Le **schéma Dockerfile complet pour Bun + Nitro (TanStack Start)** est en **annexe** ci-dessous — recopie-le si la stack correspond.

### E. .dockerignore
Allège le contexte de build : exclus `node_modules`, l'artefact (`.output`/`dist`/`build`), `.git`, `.env*` (sauf `.env.example`), IDE/outils, `storage`, tests. Ajoute l'artefact des scripts bundlés au `.gitignore`.

### F. Build + VÉRIFICATION RUNTIME (non négociable)
```sh
docker build -t <app>:opt .
docker images <app> --format '{{.Repository}}:{{.Tag}}  {{.Size}}'
docker run -d --name opt-test -p 3999:<port> <env…> <app>:opt
docker logs opt-test           # boot complet (migrate/seed → listening)
curl -fsS localhost:3999/<health>
# + un login (cookie jar) + une route qui tire les deps lourdes (PDF, image, crypto…)
```
C'est ce test qui valide « passe en prod sans souci ». Un `ERR_MODULE_NOT_FOUND` / `cannot find package` à la première requête lourde → repasse en Tier 2. Puis **nettoie** : `docker rm -f opt-test`, supprime volumes/users de test, restaure la DB de dev.

### G. Commit (via `cz` / `ga`)
`perf(docker): ship a minimal runtime image (<avant> -> <après>)` — Dockerfile + entrypoint + .dockerignore + .gitignore + doc de déploiement.

## Garde-fous (toutes stacks)
- **Jamais de Tier 1 sans les étapes B + F.** L'auto-suffisance se prouve. Un import dynamique passe le boot et casse en prod.
- **Épingle les versions de base** et **matche l'ABI** build↔runtime (musl/glibc) — sinon une dep native casse.
- **`USER` non-root + `--chown`** sur tous les `COPY`, et pré-crée les dossiers écrits (`mkdir -p … && chown …`) — un volume monté sous un user non-root échoue sinon.
- **Image sans deps = pas de script ad-hoc** dans le conteneur : bundle les outils d'ops dont l'opérateur a besoin et documente leur invocation (`docker exec …`).

## Format attendu en sortie
- Stack + runtime détectés, et palier retenu (Tier 1/Tier 2) **avec la preuve** (sortie de l'étape B).
- Tailles avant / après.
- Artefact(s) shippé(s) ; scripts d'ops bundlés ou raison du fallback Tier 2.
- Matrice de vérif runtime : boot, health, auth, + chaque route lourde testée → code HTTP / résultat.
- Fichiers touchés (Dockerfile, entrypoint, .dockerignore, .gitignore, doc).
- Compromis résiduel (si applicable).

---

## Annexe — Schéma Bun + Nitro (TanStack Start)

Cas de référence (ADZ, `963 MB → 42 MB`). **Insight clé** : le bundle Nitro (preset `bun`) est **auto-suffisant** — `.output/server/node_modules` ne contient que `tslib`, tout le reste est inliné dans `.output/server/_libs/*.mjs`. En bundlant aussi les scripts de boot, l'image runtime n'a **plus aucun `node_modules`** : on ne ship que `.output` + scripts `.mjs` + migrations sur `popwers/mini-bun` (~33 MB).

**Vérifier l'auto-suffisance avant de viser le Tier 1** :
```sh
ls .output/server/index.mjs 2>/dev/null || bun run build
ls .output/server/node_modules        # seulement `tslib` (ou vide) → Tier 1
grep -rl "PDFDocument\|@react-pdf\|sharp" src/ | head   # deps lourdes…
grep -rl "<dep>" .output/server/_libs 2>/dev/null       # …bien inlinées ?
```

**Dockerfile (Tier 1 — zéro node_modules)** — adapte les `COPY` aux assets réels (migrations Drizzle, etc.) :
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

**Entrypoint** `docker-entrypoint.sh` (migrate → bootstrap → serve ; `set -e` pour ne jamais servir sur une base non migrée) :
```sh
#!/bin/sh
set -e
bun dist-scripts/migrate.mjs        # Tier 2 : bun scripts/migrate.ts
bun dist-scripts/bootstrap.mjs      # Tier 2 : bun scripts/bootstrap.ts
exec bun .output/server/index.mjs
```
Si un script de boot affiche un chemin (« créez un admin avec … »), rends-le **agnostique du chemin** (`dist-scripts/*.mjs` en prod ≠ `scripts/*.ts` en dev) ou pointe vers la doc de déploiement.

**Gotchas spécifiques Bun + mini-bun** :
- Workdir mini-bun = `/home/bun/app` (≠ `/app`) → `STORAGE_DIR=/home/bun/app/storage`, et le `-v` du `docker run` monte là. Mets à jour la doc.
- `oven/bun:<v>-alpine` au build doit matcher le bun de mini-bun (musl). Pour figer le runtime : `popwers/mini-bun:v${BUN_VERSION}` au lieu de `:latest`.
- `--minify` inutile sur les scripts (~200 Ko) ; sortie `.mjs` = ESM sans `package.json` requis au runtime.

Pas de filler. Procède.
