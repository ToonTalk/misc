# Piskel voice-guide port — recon findings and session plan

Recon done 2026-07-03 by building Piskel from source in a fresh container. Facts below are
verified, not remembered.

## Recon: Piskel (github.com/piskelapp/piskel)

- **License**: Apache-2.0. **Status**: actively maintained — modern Vite/Biome/Playwright
  toolchain, last commit April 2026. (Any memory of a dormant Grunt project is stale.)
- **Builds clean** in a sandboxed container:
  `PUPPETEER_SKIP_DOWNLOAD=true npm install && npm run build`
  (puppeteer's Chrome download hits network allowlists; it's test-only — skip it).
- **Output decomposition** (`dest/prod/`, 5.8MB total, but 3.3MB is source maps):
  the real kernel is `piskel-packaged-min-*.js` (584K) + CSS (84K) + `index.html` (60K,
  with all UI templates inlined — DOM UI confirmed, guide architecture compatible) +
  icons.png/@2x (16K/32K) + a gif export worker (12K).
- **Single-file assembly is nearly mechanical**: index.html has exactly one external
  script slot (`{{src}}`, filled by their partials script) — inline the min.js there,
  inline the CSS, base64 the icon PNGs, and wrap the gif worker as a Blob URL.
  **Estimated single file: ~750KB.**
- **Persistence**: Piskel migrated from localStorage to IndexedDB (storage services +
  a MigrateLocalStorageToIndexedDb script). Better for artifacts than localStorage,
  but IndexedDB availability inside the artifact sandbox still needs one live check.
- **Bonus discovery**: the build generates a `piskel-web-partial-kids.html` — an official
  kids-variant page. Worth inspecting for a simplified-UI target.

## Go/no-go BEFORE session B — do these two checks (5 minutes, Ken)

1. **Artifact size**: can a ~750KB single-file HTML actually be published as a Claude
   artifact? This is the one constraint recon couldn't settle. Softened from a kill
   criterion: Ken has OpenAI credits and accepts running standalone with his own key, so
   an artifact-size failure costs only the keyless path, not the port. Still worth the
   five-minute check first, since it decides how much the tour narration should lean on
   "no key needed".
2. If (1) passes, the port session should verify IndexedDB works in the artifact sandbox
   early (one-line probe), since Piskel's save-to-browser depends on it. Export/import
   of .piskel files is the fallback and always works.

## Session A — core/adapter split (do first; short)

Inputs to upload (all five): `space_games_construction_kit.html` (latest, PASS 125 build),
`guide-layer.html` (the guide layer as a separate source file — saves carving it back out
of the spliced build; everything below the "Studio voice guide (appended layer)" comment),
`build.sh` (splices layer into the pristine app before `</body>`; session A should adapt it
to splice core + adapter), `smoke-guide.mjs`, `voice-guide-prompt.md`.

Test mechanics: `npm install jsdom`, then `node smoke-guide.mjs` next to the built HTML;
expect `PASS 125  FAIL 0`; run twice. The suite is the refactor's safety net — it must pass
unchanged (the `window.__guide` hook shape is therefore part of the frozen interface).

Task: extract the app-agnostic guide core (`vg-core.js`) from the layer and rebuild First
Day as adapter #1. **Propose the adapter interface before implementing** — the interface is
the real deliverable, and it must answer at least these boundary questions, all of which
are live seams in the current layer:
- Verb table shape: declarative entries with validate / ratifyText / exec, so ratification
  and validity-before-asking live in core while verbs stay per-app.
- Prompt hooks: `systemPrompt()` (First Day reuses the app's own builder + override) and
  `statusText()` (the STATUS RIGHT NOW block — app-specific serializer, core-owned
  placement after history).
- Layout config: panel width, palette tokens, mascot/title/greeting, and the app's
  responsive breakpoints to mirror (core generates the vg-open media queries from
  `{breakpoint, panelWidth}` rather than hard-coding 1180/302).
- Takeover config: which trusted events auto-pause (First Day: pointerdown+keydown;
  keyboard-heavy apps like Piskel: pointerdown only).
- App-specific patches that are NOT core but need an adapter init hook: the
  callLLM/askRoleAI keyless wrap, the open-studio scroll watcher, confirm-dialog
  hints/extra-buttons keyed by message.
- Deliverable shape: the shipped app remains ONE html file — vg-core.js is authoring-time
  reuse (spliced in by the build), not a runtime dependency.

Deliver: vg-core.js, the re-split First Day file (tests green), and a doc revision
replacing "port the reference" with "here is the core; write the adapter" plus the
adapter interface spec.

## Session B — Piskel port (adapter #2, first external field test of the doc)

Inputs to upload: `vg-core.js`, `voice-guide-prompt-v3.md` (the "write the adapter" revision
from session A), this file.

Carried forward from session A, to check live early:
- Piskel defines none of the `--panel/--ink/--accent` CSS variables, so the panel will get
  core's dark fallbacks — the adapter should restyle via layout/palette config to match
  Piskel's own look.
- Bands-before-mirror CSS ordering is core policy but was only test-verified structurally
  (jsdom has no cascade); confirm reflow visually at ~1300px and ~600px widths.

Steps:
1. Clone and build Piskel per the command above; assemble the single file from
   `dest/prod/` as described; verify it runs standalone from disk before touching the
   guide (open, draw, add a frame, export a PNG).
2. Fill in the doc's per-app blanks from the recon: audience = kids/beginners (consider
   the kids partial); no existing LLM plumbing → keyless-Anthropic default with
   multi-provider fallback; confirm()/alert() audit; responsive breakpoints to mirror.
3. Adapter: tour spine over tools → canvas → frames/animation preview → layers →
   palette → resize/export; snapshot over the Piskel document (frames, layers, palette,
   current tool/color, canvas dimensions) for provenance diffs ("you added two frames
   and switched to the eraser"); DO verbs likely TOOL / COLOR / FRAME / LAYER / SHOW /
   PLAY / SPEED, with anything destructive (delete frame, resize, new) ratified.
4. Full smoke suite per doc invariant 12; report with PASS-count fingerprint.

## Risks carried into session B

- Artifact size ceiling (go/no-go above) — the whole keyless story hangs on it.
- Guide layer must not collide with Piskel's own keyboard shortcuts (it has many) —
  the trusted-keydown auto-pause will fire constantly while drawing; expect to tune
  takeover to pointerdown-only or scope keydown handling.
- Piskel's drawing surface is canvas (fine — toolbars/panels are DOM and are what the
  guide points at), so pixel-level provenance is out of scope; frame/layer/tool-level
  diffs are the right grain.
- The gif worker inlining (Blob URL) needs a live export test in the artifact sandbox.
