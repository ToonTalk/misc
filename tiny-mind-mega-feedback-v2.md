# Tiny Mind mega build — audit + live-bug report (v2; replaces v1 entirely)

To the session that assembled `tiny-mind-mega.html` (597,409 bytes). An independent
audit extracted your build (byte-identical reassembly roundtrip) and then the
acceptance test was run for real: `zog-arc.zip` (the actual shipped pack: flat layout,
valid manifest, 10 snapshot .bins) dropped into the bay.

## Part 1 — what the audit confirmed landed

All of it: the time machine (src/scrubber.js, manifest-driven, prefix-tolerant, arc
picker), scrubMoved/scrubCommitted seam events, keep-raising-from-here, shell autoload
of arc/arc-manifest.json with lazy bins over arc.snapshot RPC, little-kid labels,
GENERATED stamps without volatile dates. Downstream drop machinery too:
splitArcPacks (manifest + claimed sibling bins, kept OUT of the model pool),
shellArcs.snapshotBytes serving dropped bins first with fetch fallback and caching,
and the nursery's retrying __tmArc handshake. Credit where due — the architecture for
dropped packs is complete and correct.

## Part 2 — the live bug: the recognizer runs before the decompressor

Observed on drop of zog-arc.zip: no time machine; nine arcB-step*.bin entries in the
model pool each demanding a tokenizer; bay status "… sent 1 json to the nursery."

Root cause, from your code: `shellIngest(recs)` calls `splitArcPacks(recs)` on the
INITIAL records, but zips are only expanded later, inside the classify queue
(`if .zip → queue.push(...await unzip(...))`). A dropped arc pack is one zip record
at split time — no json visible, no arc found. The loop then unzips it and the inner
files hit the ordinary classifiers: the manifest goes down the storybook-json path to
the Nursery, every snapshot .bin lands in the model pool. The drop path therefore
works only for LOOSE manifest+bins drops — a form that is never shipped. The autoload
path is unaffected, which is why serving with arc/ beside the file works.

## Part 3 — fix

Restructure shellIngest into three phases:
1. GATHER: recursively expand all zips into a flat record list first (depth cap ~3;
   this also makes nested packs work, e.g. a starter zip containing an arc zip).
2. SPLIT: run splitArcPacks on the flat list; take arcs.
3. CLASSIFY: the remainder through the existing tokenizer/checkpoint/json loop.
No changes needed downstream — takeArc/snapshotBytes/__tmArc are already correct.

## Part 4 — the regression test that must exist

The arc-session kickoff specced "built arc zip → existing ingest → correct pool
contents." Either it was not implemented or it fed pre-unzipped records. Required:
- Feed the RAW BYTES of the actual shipped zog-arc.zip through the true ingest entry
  point (the same function the drop handler calls).
- Assert: model pool count unchanged; shellArcs contains arcB with 10 snapshots and
  10 bins aboard; a tm:'arc' message was sent to the nursery; NO tm:'json' message
  was sent; the bay said the arc-pack line, not "sent N json".
- Add the nested case: a zip containing zog-arc.zip plus a loose tokenizer.
- End-to-end smoke: after ingest, scrub-release loads a snapshot via arc.snapshot
  (bins path, no fetch), and keep-raising initializes the trainer from it.

## Part 5 — retained requests from v1 (all still stand)

1. Always-visible time machine stub when no arc is loaded: one line of copy stating
   what it is and what to drop; little-kid variant. Gated features must be
   discoverable in their gated state — this build's correct features were reported
   missing by its own user, twice, for exactly this reason.
2. Surface autoload outcomes in bay status ("looked for arc/arc-manifest.json — not
   found here") instead of silent catch; same for replay.json and model eager-loads.
3. Ship a self-verification block with every build (feature → activation condition →
   greppable probe; sha256 per dist file; suite PASS counts at build time).
4. Stamp nit: "works from file://" is true for the singles, false for the mega
   (opaque-origin frames, per your own technical report). Scope the stamp per file.
5. Pool-copy nit: every vocab-512 checkpoint is described as "a mind you raised in
   the Nursery" — untrue for e.g. the pristine base model; describe by provenance
   only when known.

## Acceptance test for the next build

Fresh profile, three contexts (pasted artifact, file://, http without arc/):
time machine stub visible and self-explanatory; bay accounts for every autoload it
attempted. Then drop zog-arc.zip in each context: the stub becomes the live scrubber
with arcB selected and the parroting tail reachable; scrub-release loads snapshots
without network; keep-raising starts training from the selected step. No snapshot
.bin appears in the model pool at any point.
