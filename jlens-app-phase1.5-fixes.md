# Brief: J-Lens Explorer — Phase 1.5 fixes

Ordered by importance. No new features beyond these; Phase 2 (WebGPU,
grinding) remains separately gated.

## 1. Swap semantics and presentation (the big one)

Current behavior: swap runs two fresh seeded generations from the anchor
(no-edit vs edit) at the current temperature and labels the no-edit run
"before". Users read "before" as their original story; it isn't.

- Three panes: **original** (verbatim from the current analysis/generation),
  **rewrite (no swap)**, **rewrite (with swap)**. One line of copy: "from the
  anchor, the model rewrites the story twice — the ONLY difference between
  the two rewrites is the swap."
- Default swap reruns to temperature 0 (deterministic); keep the current
  temp as an advanced option.
- Regenerate from the ANALYZED TOKEN IDS up to the anchor — not re-encoded
  text (kills the token-boundary drift known issue).
- Busy state: disable the button, show a spinner AND stream tokens into
  both rewrite panes as they generate (the worker already posts gen-token
  messages; render them).
- Anchor-on-the-word confusion: when the source word itself is in the
  prefix (e.g. anchor = "beach"), note in copy that the visible word stays —
  the swap changes the model's state from that point on, not written text.

## 2. Swap word inputs

The datalist currently contains only meta.themeWords. Populate it with:
(a) the current story's single-token words (deduped, story order) as the
first group, then (b) theme words. Label the inputs "single-token story
words work best". Keep the multi-token rejection guard and its message.

## 3. Background-tab handling

Compute is timer-free in the worker, so plain backgrounding is full speed
on desktop; the risks are tab discard (Chrome Memory Saver) and OS/browser
energy modes.
- Put progress in the tab title during analyze/generate/swap ("⏳ 43% …").
- Self-check: measure tokens/s; if document.hidden and throughput drops
  > 3x below the session's foreground baseline, show a banner on return:
  "your browser slowed this tab while hidden".
- Cache the readout dictionaries (and lens + vocab) in IndexedDB keyed by
  file hashes — makes discarded-tab recovery cheap AND removes the ~30 s
  dictionary build from the load path on revisits (build lazily per layer
  on first run).

## 4. Copy fixes

- Panel 2's "click any word" must say it means the STORY panel's words
  (panel 3), e.g. "click any word in the story below".
- Heat hint stays on the readout panel; add the same hint as a tooltip on
  chips.

## 5. Performance (do last)

Shard matmulFast rows across (navigator.hardwareConcurrency - 2, min 2,
max 6) workers for the forward pass and dictionary build. Target: analyze
207 tokens < 15 s on the reference Xeon. No SIMD/WebGPU in this phase.

## Acceptance

1. Swap on a pasted story shows the original verbatim plus two rewrites;
   with temp 0, running the same swap twice gives identical panes.
2. Fixture parity still 1.0 (run node test/parity.mjs — the analyzed-ids
   change must not alter tokenization of fixtures).
3. Reload with cached files: interactive (dictionaries ready or lazily
   building) in < 5 s, no 30 s stall.
4. Analyze progress visible in tab title; hidden-throttle banner works
   (test by forcing a fake baseline).
5. README updated: swap semantics section, background-tab notes, new
   timings.
