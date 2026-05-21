# Frontend Performance Rules

Inspired by the Linear performance breakdown (https://performance.dev/how-is-linear-so-fast-a-technical-breakdown). Apply to any UI work in React, Astro, or Tanstack Start.

## Animation Speed Tokens

Use a single source of truth for transition durations. Industry defaults (200–350 ms) feel sluggish — Linear's tokens reflect that.

```css
:root {
	--speed-highlightFadeIn: 0s;
	--speed-quickTransition: 0.1s;
	--speed-regularTransition: 0.25s;
	--speed-slowTransition: 0.35s;
}
```

Rules:

- Asymmetric timing is the default: apparition instantanée (0 s ou `--speed-highlightFadeIn`), fade-out plus lent (`--speed-quickTransition` ≈ 100–150 ms). Le retour visuel à l'utilisateur doit être immédiat.
- Tooltips, hover states, focus rings → `--speed-highlightFadeIn` (instant).
- Buttons, small toggles, tab switches → `--speed-quickTransition`.
- Panels, dropdowns, sidebars → `--speed-regularTransition`.
- Modals, page-level transitions → `--speed-slowTransition`.
- Never animate longer than 350 ms without an explicit motion-design reason. If you reach for 500 ms+, the animation is decorative — cut it.

## Render First, Authenticate Second

Pattern for any app with login + cached workspace data (Tanstack Start, BetterAuth, Strapi-backed apps).

Boot order:

1. **Synchronous read of a local marker** (`localStorage.ApplicationStore`, an IndexedDB key, or a cookie hint). If the marker exists, the user has visited before and the cached shell is trustworthy.
2. **Render the shell immediately** with cached tokens (theme, sidebar width, dark mode, last route). No network round-trip before paint.
3. **Validate the auth token in the background.** Fire the request after the first frame.
4. **On 401**, redirect to login asynchronously. The user sees the shell first, then the redirect — not a blocking spinner.

Anti-patterns to avoid:

- Blocking the first paint on a `fetchUser()` call.
- Showing a full-screen spinner during the auth check.
- Re-fetching data the cache already has just to "be safe" — invalidate granularly instead.

Apply when:

- The app has logged-in users with persistent workspace state.
- The shell layout (sidebar, nav, theme) is stable across sessions.
- Initial paint matters more than absolute freshness of the first byte of data.

Skip when:

- The route is genuinely server-rendered with per-request data (e.g. marketing pages, OG-tagged share targets).
- The user state is so volatile that stale shell would mislead (rare).
