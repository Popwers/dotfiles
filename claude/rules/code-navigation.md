# Code Navigation Stack

Three complementary layers — pick the one that matches the question, don't stack them on the same query.

| Question | Tool | How |
|----------|------|-----|
| "Where is the code that does X?" (conceptual) | grepai | `grepai search "<intent>" --json --compact` |
| "Who calls this / where is it defined / what's in this file?" | Serena MCP | `find_symbol`, `find_referencing_symbols`, `get_symbols_overview` |
| Exact string/pattern, known symbol name | rg / Grep | `rg "validateToken" --type ts` |
| "How is this system architected?" (unfamiliar codebase) | Graphify artifact | Read `graphify-out/GRAPH_REPORT.md` / `graphify-out/wiki/index.md` |

## Serena: read symbols, not files

- Before reading a whole source file, ask: do I need the file or one symbol? For a symbol, use `get_symbols_overview` then `find_symbol` with `include_body=true` — not Read.
- Impact analysis before modifying a shared function: `find_referencing_symbols` on the symbol, not a repo-wide grep.
- Renames and signature changes: enumerate call sites via Serena references first; grep only to catch string literals and dynamic imports.
- Full-file Read remains correct for: small files (<100 lines), config/markdown, files you are about to rewrite, and when Serena has no language server for the file type.
- If Serena tools are unavailable or erroring, fall back silently to grepai + rg + Read. Never block on it.

## Graphify: one-shot maps, not a live tool

- Graphify is consumed as a **persisted artifact**, not a per-session tool. If `graphify-out/` exists in the repo, read `GRAPH_REPORT.md` (god nodes, communities, surprising connections) before any broad exploration — it replaces several discovery rounds.
- Generate or refresh a map only when explicitly asked or when starting deep work on an unfamiliar codebase: `/graphify .` (skill) or `graphify --update` for incremental refresh.
- Treat edge labels honestly: `EXTRACTED` is fact, `INFERRED`/`AMBIGUOUS` are hypotheses to verify in code before relying on them.

## Anti-patterns

- Asking two tools the same question "to be sure" — pick one, trust it, verify in code only if the answer is load-bearing.
- Reading a 400-line file to see one function signature.
- Repo-wide grep for callers when a language server knows the references.
- Re-running a full Graphify build when `--update` (SHA256 cache) suffices.
