# Tiny Mind — Arc Generation Kickoff (Claude Code session)

Repo context: Phase 0 report (`report.md`); dev-tree fingerprint 47 PASS 0 FAIL plus
the mega-build suites. All engine changes additive; gradcheck and G1 parity stay green.

## Scope — read first

This session (Claude Code, Ken's machine): build `tools/make-arc.js` (it does NOT
exist yet — it is this session's primary deliverable), run both arcs, extend the Pages
autoload, package the zips, tests. This session does NOT touch the artifact edition:
the scrubber UI and its kid-facing labels belong to a later claude.ai session that
edits the artifact build. That session receives only outputs and contracts — never the
tool. The handoff section at the end of this file is written to be pasted into it.

## Goal

Precomputed checkpoint snapshots along two training arcs so the Nursery (later) can
offer a scrubber: drag through developmental time, instant sample + losses from a
manifest, checkpoints lazy-loaded only on demand. Rationale: live from-scratch training
is hours; 120 live steps from random init ends at "Zogididid" and teaches "training
doesn't work."

## Two arcs

**Arc B — fine-tune (build first; ~25 min run).** Pretrained stories260K → Zog corpus,
exactly the E5 recipe (B=8, T=192, lr 3e-4, replay 50%, seed recorded). Snapshots at
{0, 10, 20, 40, 80, 120, 200, 400, 600} — deliberately past the held-out floor into the
parroting regime; scrubbing through absorption AND overfitting is the E5 story made
tactile.

**Arc A — from-scratch (overnight; truncatable).** Random init (worker's randomWeights,
fixed seed) on GENERAL data — from-scratch on 17K Zog tokens memorizes rather than
develops. Data: extend the replay pipeline to ~2000 TinyStories-valid stories (~700K
tok512 tokens; build once, cache the token stream). Short lr probe first ({1e-3, 3e-4},
200 steps). Snapshots log-spaced {0, 20, 50, 100, 250, 500, 1000, 2500, 5000, 10000,
20000}; at ~2.05 s/step, 20K steps ≈ 11.4 h, so every snapshot is written as reached
and the manifest is valid at every prefix (safe to stop at dawn). Honest expectation,
recorded in manifest notes: fully-trained stories260K is only barely grammatical; the
endpoint is "story-shaped with frequent errors" — the STAGES are the exhibit.

## Deliverable 1: `tools/make-arc.js`

- Config block: arc name, start (checkpoint path | 'random'+seed), data streams,
  recipe, snapshot schedule, eval cadence, fixed sample prompts.
- Resumable EXACTLY: beside each snapshot write `state-<step>.json` (step, RNG state)
  plus serialized Adam moments (m/v). Resume-determinism test: 100 straight steps vs
  50+interrupt+50 → byte-identical final checkpoint.
- Per snapshot, append to `arc-manifest.json`: step, filename, recent-mean train loss,
  zogHeld + base losses where applicable, greedy samples for fixed prompts ("Once upon
  a time" both arcs; "One day Zog" Arc B).
- Files: legacy fp32 .bin via writeCheckpoint, no new formats. Naming
  `arc{A|B}-step{00000}.bin`. Sizes: B ≈ 9×1.06 MB, A ≤ 11×1.06 MB ≈ 12 MB.

## Deliverable 2: packaging + Pages autoload

- Shell autoload additionally fetches `arc/arc-manifest.json` up front (and nothing
  else); .bins remain lazy.
- Zips for the artifact edition (ingest already handles zips): `zog-arc.zip` (Arc B),
  `newborn-arc.zip` (Arc A), each with its manifest inside.
- Starter-pack recomposition per Ken: `tiny-mind-starter.zip` = trainee .bin + tok512 +
  replay.json only (~1.5 MB). Arc packs are separate optional zips. The 15M specimen +
  32K tokenizer is a separate optional ~60 MB download, never on the golden path.

## Deliverable 3: tests (fingerprint monotone)

- Manifest schema check; every listed snapshot parses via readCheckpoint.
- Resume determinism (above).
- CI mini-arc: 30-step schedule exercising the whole tool end to end.
- Zip round-trip: built arc zip → existing ingest → correct pool contents.

## Open items for Ken during the session

(1) Arc A data size vs. overnight budget — the lr probe will say whether 2000 stories
suffices by 20K steps or the slice should grow. (2) Whether Arc B's parroting tail
(400/600) shows samples degraded enough to keep for kids, or 200 is the better last
stop. (3) Where 12 MB of snapshots lives (main repo vs. release asset fetched by URL).

---

# HANDOFF — paste into the future claude.ai scrubber session

You are editing the Tiny Mind artifact/mega edition. Arc snapshot packs already exist
(generated offline; you do not need or receive the generation tool). Contracts:

- **Arc pack**: a zip containing `arc-manifest.json` + `arc{A|B}-step{NNNNN}.bin`
  files (legacy llama2.c fp32 checkpoints, vocab 512). The shell's existing zip ingest
  accepts a dropped pack; on Pages the shell autoloads `arc/arc-manifest.json`.
- **Manifest schema** (per arc): `{ arc, note, config:{B,T,lr,replayRatio,seed,start},
  snapshots:[{ step, file, trainLoss, zogHeld?, baseLoss?, samples:{prompt:text} }] }`
  — valid at every prefix; never assume the full schedule is present.

Build in the Nursery frame:
1. **Scrubber UI**: a slider whose stops are the manifest snapshots. While dragging:
   show the manifest's greedy sample + position markers on the existing loss chart —
   instant, no .bin loads. On release: load that snapshot into the model pool (existing
   load path). Button "keep raising it from here" initializes the trainer from the
   selected snapshot; make the chosen start point visible so the child knows which mind
   they are continuing.
2. **Little-kid labels**: Arc A = "a brand-new mind growing up"; Arc B = "the trainee
   learning Zog (and then just memorizing)". Snapshot captions from manifest samples.
3. Keep everything additive; the training worker's message protocol is unchanged
   except the start-from-snapshot init, which reuses the existing load-pair path.
4. Tests in the mega suite style: manifest → slider renders N stops; sample text swaps
   while dragging without any checkpoint fetch; start-from-snapshot round-trips.
