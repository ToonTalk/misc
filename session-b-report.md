# Session B report — Piskel adapter (voice-guide port #2)

Status: COMPLETE. Live build confirmed working by Ken. This file is the
fingerprint ledger + findings record; it belongs in project knowledge so
future chats can verify uploads against it (builds themselves are never
stored in project knowledge — upload per chat).

## Current fingerprints (2026-07-04)

Suite: **PASS 93 / FAIL 0, run twice** (node smoke-piskel.mjs; deps jsdom +
fake-indexeddb + canvas or @napi-rs/canvas — the suite auto-shims the latter;
jsdom stubs documented in the suite header; different deps = different result).

| file | bytes | sha256 (first 16) | role |
|---|---|---|---|
| piskel-guided.html | 929,370 | b7ae0d0b58314c1e | THE build — publish as artifact |
| piskel-adapter.js | 32,308 | 0d95e792714602a2 | adapter, project resource |
| smoke-piskel.mjs | 27,980 | 33d8805e09c7af21 | suite, project resource |
| build-piskel-guided.sh | 1,020 | 696f923883a7b324 | splice build, project resource |
| assemble-single.mjs | 4,049 | c1c48dde370be8b7 | Piskel→single-file assembler |
| piskel-single.html | 860,461 | 6210615ed1969fe3 | pristine app input (per-chat upload) |
| vg-core.js | 36,563 | 281c49bb21feb50b | UNCHANGED — no fork this session |
| space_games_construction_kit_resplit.html | 174,889 | bae7cad164cd5c23 | First Day rebuilt (PASS 125×2); replace the stale stored copy |

Piskel source: github.com/piskelapp/piskel @ a6b9c02 (2026-04-09). Rebuilding
from source changes piskel-single.html's hash (build timestamp is stamped in).

## Doc findings for v3→v4 (field-tested, not yet applied)

1. `reflowCSS` has no unconditioned slot; fixed-position apps (Piskel) can't
   use body-margin reflow. Proposal: `reflowCSS.always`. Worked around via
   adapter-injected `#vgAppStyle`; suite asserts it config-derived.
2. PASS count is not a build fingerprint across refactor boundaries (First Day
   monolithic and re-split both = 125). sha256 is the discriminator.
3. `clickSel` assumes click-driven controls; Piskel tools are mousedown-driven.
4. Invariant 9 (below-the-fold reveal) n/a for single-screen apps.
5. File-drop confirms have no re-trigger button; the press-again toast wording
   ("press the same button again") reads oddly for drops.
6. NEW: the DO-line syntax (`DO:` with colon) lives only in core's parser
   regex — nowhere canonical for adapters. My prompt taught bare `DO` and the
   suite caught it. Proposal: add `fragments.doLineFormat` to core, or state
   the exact format in the doc's prompt-composition section.

## Piskel-specific traps (for anyone touching this adapter)

- Piskel's data-uri export template embeds a nested `</body>`; the build
  splices at lastIndexOf and asserts placement.
- Modern Piskel uses `data-test-id` for layer/palette controls; the old `id=`
  attributes exist only inside text/template blocks.
- Piskel's body-click handler closes an expanded drawer on any outside click —
  anything opening a drawer from inside another click handler must defer one
  tick (see the confirm-rule "Export first" onExtra).
- Layer selection requires the click to land on the `.layer-name` child.
- Merge is disabled on the bottom layer; MERGE_LAYERS validates to a silent
  no-op there (asserted as a feature).

## Judgment calls (Ken: bless or veto)

- 🔑 key button injected into core's `#vgControls` (Piskel has no settings
  surface to host it).
- `$.publish(Events.SELECT_PRIMARY_COLOR)` treated as "real controls one
  level down" — same bus the buttons publish on.
- Per-verb gating split: DELETE_FRAME / DELETE_LAYER / MERGE_LAYERS / RESIZE
  as own gated verbs (core gating is static per-verb).
- Hide-toast and notify ride Piskel's own notifier (SHOW/HIDE_NOTIFICATION).
- Confirm tier-1 tested via scratch buttons, not a genuine Piskel handler
  (needs saved state to orchestrate) — live-eyeball item.
- LLM defaults: anthropic `claude-sonnet-4-6`, openai `gpt-5.1`,
  google `gemini-3.5-flash` (verified GA 2026-07; the preview id is
  gemini-3-flash-preview). All user-editable in the key dialog.

## Open items

- Doc v3→v4 revision: recommend AFTER adapter #3 (two data points aren't
  enough to freeze the reflowCSS.always seam shape); findings are banked here.
- Core edit candidates parked (propose-before-building): reflowCSS.always,
  fragments.doLineFormat.
- Replace the stale First Day build in whatever store served it.
- Live-eyeball stragglers (headless-blind): narrow-window bottom dock;
  reflow with drawer expanded (582px rule); artifact save→reload
  (IndexedDB in sandbox); GIF export worker in sandbox; keyed round-trip
  with a real key; mic behavior in the artifact.
- Pick adapter #3.
