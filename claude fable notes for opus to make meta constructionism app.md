# CLAUDE.md — The Atelier

Single-file web app where children build and experiment with small constructionist agents that draw (turtle graphics) or write short poems, exhibit work, get critiques, reflect, and improve over rounds. Read `SPEC.md` fully before writing code; it is the contract.

## Project shape

```
atelier/
  SPEC.md            # the contract — consult before and after every milestone
  CLAUDE.md          # this file
  atelier.html       # THE app. One file. Everything lives here.
  tools/             # dev-only; never required at runtime
    harness/         # Playwright screenshot harness (see Testing)
    references/      # reference PNGs for turtle output comparisons
  notes/             # decision log (append-only DECISIONS.md)
```

## Hard rules

1. **One runtime file.** `atelier.html` only: vanilla JS, inline CSS, zero external requests except LLM APIs. No frameworks, no CDN, no build step. Must work from `file://`.
2. **Glass box.** Never add a prompt or behavior the student can't inspect via the "peek under the hood" view. All child-facing strings and starter-mind templates live in the `COPY & TEMPLATES` section so they're easy to edit.
3. **Section banners.** Keep the section layout from SPEC §14 and navigate by banner. When editing, prefer surgical str_replace edits within a section over rewriting sections.
4. **Reading age ~9** for all Studio-mode copy. Science Corner copy may be ~14+. When in doubt, simpler.
5. **Never lose student work.** Persist after every phase, not every round.
6. **Model ids live in `MODEL_DEFAULTS` only.** Verify current ids against https://docs.claude.com/en/docs_site_map.md (and OpenAI/Google docs) before changing; users can override any id in Settings. Artifact mode uses `claude-sonnet-4-20250514`, `max_tokens: 1000`, keyless.

## Development workflow

- Serve with `python3 -m http.server 8741` for harness runs (the sandbox iframe and fetch behave more uniformly over http), but verify `file://` still works at each milestone.
- Follow milestones M0→M4 in SPEC §15 strictly; do not start a milestone before the previous one's acceptance checks pass. Record each milestone sign-off in `notes/DECISIONS.md`.
- Mock mode first: implement the `mock` provider (SPEC §14) before any real API wiring, and keep all harness tests on `?mock=1` so CI never spends tokens.

## Testing with the screenshot harness

The canvas is animated; screenshots of mid-animation frames are nondeterministic. Use the provided hooks:

- `?instant=1` renders final turtle state with no animation.
- `window.__atelier.renderTurtle(code)` draws synchronously and resolves when the snapshot exists.
- `window.__atelier.runPhase(...)` steps the round engine one phase at a time under mock mode.

Per-milestone harness checks (keep these as named scripts in `tools/harness/`):

- **M0:** render the reference spiral via `renderTurtle`, compare against `tools/references/spiral.png` (pixel diff tolerance ≤ 1%); trigger a deliberate runtime error and screenshot the friendly error card.
- **M1:** drive 5 full mock rounds; assert journal has 5 entries, lessons ≤ 5, localStorage survives reload mid-round (reload between phases 4 and 5 and assert no data loss).
- **M2:** mock crit session with 3 agents; assert humanEdited diff note appears in the next composed maker prompt (read it from the peek-under-the-hood DOM).
- **M3:** export gallery HTML, open it in a fresh page, screenshot; trading-card JSON round-trip equals deep-equal (modulo ids).
- **M4:** Eyes-on/off mock experiment, 6 rounds; validate CSV row count = 2×6×3 metrics; unit-check aHash on two bundled reference images (known Hamming distance).

## Style

- Plain functions + a single global `state` object with explicit `save()`; no classes unless they pay rent. JSDoc types matching SPEC §3.
- Hand-rolled where cheap: aHash (~30 lines), Jaccard, line-diff summary, SVG charts. Do not add libraries for these.
- Errors surface as friendly cards in the UI *and* `console.warn` with structured detail.

## When uncertain

Prefer asking the owner over inventing: especially for child-facing copy tone, starter-mind templates, and anything that would add a dependency or a second file.
