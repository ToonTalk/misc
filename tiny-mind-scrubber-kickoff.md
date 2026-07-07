# Tiny Mind — Scrubber Session Kickoff (fresh claude.ai session)

You are editing the Tiny Mind ARTIFACT/RELEASE edition. The arc snapshot packs were
generated offline by a separate Claude Code session; you do not need or receive the
generation tool. Arc B ("zog-arc.zip") exists now; Arc A ("newborn-arc.zip") is still
computing and MUST NOT be required by anything you build.

## Single-source rule (non-negotiable)

The Nursery exists twice: standalone release file and as a template inside
`tiny-mind-mega.html`. All edits go into the RELEASE FILE(S); Ken rebuilds the mega
locally with `build-mega.js`. Never edit the mega directly — that forks the codebases.
If a change is needed in the shell (arc autoload, pool behavior), edit the shell
source that build-mega.js consumes, same rule.

## Inputs Ken uploads at session start

1. Current Nursery release file (and shell source if needed) — confirm exact filenames.
2. `tiny-mind-build-report-technical.md` — read it FIRST; it is the distilled record of
   the artifact sandbox's actual rules (blob workers blocked, DataTransfer neutered
   across awaits, downloads only from the top frame, CSP allows only Anthropic,
   file:// is an opaque origin). Do not re-derive these by hitting the walls again.
3. `zog-arc.zip` (Arc B pack) for drop-testing.
4. Current fingerprint / PASS status note from the arc session.

## Confirm before coding (ask Ken, batched)

(a) Did the arc session's shell-autoload extension (`arc/arc-manifest.json`) land, and
what is the built mega's current PASS state? (b) Does the worker's init path already
accept an arbitrary start checkpoint via load-pair, or does start-from-snapshot need a
small additive worker change? (c) Where in the Nursery UI the scrubber sits (Ken's
call). (d) Whether the STANDALONE Nursery also autoloads an `arc/` folder beside it,
or scrubber data arrives only via drop/shell in standalone mode.

## Contracts

- **Arc pack**: zip containing `arc-manifest.json` + `arc{A|B}-step{NNNNN}.bin`
  (legacy llama2.c fp32 checkpoints, vocab 512). Existing zip ingest accepts a dropped
  pack; on Pages the shell autoloads the manifest.
- **Manifest schema** (per arc): `{ arc, note, config:{B,T,lr,replayRatio,seed,start},
  snapshots:[{ step, file, trainLoss, zogHeld?, baseLoss?, samples:{prompt:text} }] }`
- **Prefix validity**: a manifest may contain any prefix of its schedule. Never assume
  a particular snapshot count, spacing, or final step. Multiple arcs may coexist in the
  pool; the picker is data-driven from `arc` and `note` fields. Arc A arriving later
  must require ZERO code changes — that is the acceptance test of the design.

## Build

1. **Scrubber UI** in the Nursery: slider whose stops are the loaded manifest's
   snapshots. While dragging: show the manifest's greedy sample and position markers on
   the existing loss chart — instant, no .bin loads. On release: load that snapshot
   into the model pool via the existing load path. Button "keep raising it from here"
   initializes the trainer from the selected snapshot, with the chosen start point
   visibly named so the child knows which mind they are continuing.
2. **Labels**, data-driven with little-kid variants: Arc B = "the trainee learning Zog
   (and then just memorizing)"; Arc A = "a brand-new mind growing up". Caption each
   stop from its manifest sample.
3. **Additive only.** Worker protocol unchanged except (b) above if needed. The
   engine's parity/gradcheck paths are untouchable.

## Working loop and discipline (from the prior artifact session — keep it)

Edit release file → `node --check` every extracted script layer (page and worker) →
run the added jsdom tests in this session's sandbox → hand the file back → Ken rebuilds
mega + pastes into a live artifact → console errors and screenshots drive the next
iteration. Worker-string edits use extract → edit → re-embed with an exact byte
round-trip assertion. Every delivered build is fingerprinted by suite PASS count;
counts are monotone.

## Tests to add

- Manifest → slider renders N stops for several prefix lengths (1, 3, all).
- Dragging swaps sample text with zero checkpoint fetches (spy on the loader).
- Start-from-snapshot round-trips (snapshot in → trainer init → first step runs,
  finite loss) against a synthetic mini-manifest + tiny checkpoint.
- Dropped zog-arc.zip populates the picker; a second manifest coexists without
  collision.

## Parked — do not build here

Guide/commentary interplay with the scrubber (whether narration runs over scrubbing)
belongs to the dedicated guide session; leave a clean seam (the scrubber should emit
`scrubMoved(step)` and `scrubCommitted(step)` events for the future guide to consume,
and nothing more).
