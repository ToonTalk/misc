# J-Lens Explorer guide — session kickoff (adapter #3)

For the voice-guide Claude Project, Piskel-session-B pattern. This doc is the
bridge from the J-lens build conversations, which the project session cannot
see — everything the adapter and the guide's system prompt need to know about
the app is here.

## Inputs to upload

`vg-core.js`, `voice-guide-prompt-v3.md`, this file, and the CURRENT
`jlens-explorer.html` (Phase 1.5 build — verify it's the IndexedDB/pool
build by checking the README fingerprint before splicing).

## Pre-fixes to land in the app BEFORE the adapter (small, do first)

1. Rename the temperature slider — it's currently "heat", which collides
   with "heat strip" (unrelated concept). Candidate: "surprise". Update the
   done-line and any copy that says heat-as-temperature.
2. Strength slider: add a marked recommended band (~0.2–0.5) so "keep it
   low" is visible, not just stated.
3. Dictionary progress bar copy: "one-time setup: building the lens's
   word-directions (cached after today)".

## App anatomy (panel numbers as on screen)

1 — file loading (fetch/drop; IndexedDB-cached, <1 s on revisit).
2 — get a story in: prompt box, starter chips, ANALYZE (read a pasted
    story) vs GENERATE (model writes on), surprise slider, max tokens.
3 — the story token-by-token; clicking a word selects it.
4 — "what it's holding in mind": per-layer rows L4–L8; modes J-lens /
    logit lens / DIFF; raw and top-20 toggles; pink chips = name
    fragments; "model's next word" row; ranks are within story vocab.
5 — swap: take-out/put-in words, anchor = selected token, layer range,
    strength, "use story heat" (rename per pre-fix 1), swap & rewrite →
    THREE panes: original / rewrite-no-swap / rewrite-with-swap.

## Concept glossary — the guide's system prompt MUST encode these exactly

- The model carries a hidden vector per word per layer. The J-lens
  translates mid-layer vectors into words the model is DISPOSED TO SAY —
  now or a few sentences later. The logit lens shows what it would BLURT
  OUT if it stopped at that layer. DIFF = words only the J-lens sees
  (green): the layer's hidden anticipation.
- Layers L4–L8 are shown because below that readouts are static and above
  it the two lenses converge.
- Short prompts give thin readouts: the model has nothing to hold in mind
  yet. The lens gets interesting a few sentences in. Set this expectation
  EARLY in the tour.
- Names and rare words often split into pieces (Lily → " L"+"ily");
  pink chips like "L… (Lily?)" mean the model is thinking of a word that
  starts that way. Out-of-vocabulary names (Zog) only ever appear as
  fragments.
- raw toggle = show everything the lens sees, including word-pieces and
  punctuation — messier but nothing hidden. Filtered view shows whole
  words only.
- Swap semantics (get this precisely right): from the anchor, the model
  rewrites the story TWICE with the same seed; the ONLY difference is the
  swap. Rewrites default to surprise 0, so they're exact and repeatable.
  Words already written before the anchor stay — including the swapped
  word itself if it's there: the swap changes what the model is THINKING
  from the anchor on, not text it already wrote. The edit is self-gating:
  it scales with how much of the take-out concept is actually present, so
  swapping out a word that isn't "on its mind" does nothing.
- The classic demo: in "Max dug a hole", swapping hole→castle produced
  "moat" — the castle-thing-you-dig. The edit lands on the concept, not
  the word. Use this story when a child asks what swap is for.
- Heat strip: click any readout chip → the story lights up where that
  word ranked high in the model's mind (mid-layer J-lens rank).

## Tooltip copy (controls; paste-ready, adapter or app-side)

- surprise slider: "How adventurous the word choices are. 0 = always its
  top pick (same story every time); higher = more surprises."
- max: "How many new tokens the model may add before stopping."
- raw: "Show everything the lens sees — word-pieces, punctuation — not
  just whole words. Messier, but nothing hidden."
- top-20: "20 guesses per layer instead of 8. Interesting things
  sometimes hide at rank 9–20."
- readout chips: "Click to light up the story wherever this word was on
  the model's mind."
- strength: "How hard to push the swap. Low = a nudge the story can
  absorb; high = a shove that can break its grammar. Stay in the green."
- use story heat → rename "surprising rewrites": "Rewrites normally use
  surprise 0 so the comparison is exact and repeatable. This uses the
  story's surprise setting instead — livelier, but each run differs."

## Tooltip → guide bridge (Ken's addition — likely core, not adapter)

Implement tooltips in JS from a single registry per app:
`{ id, target, oneLiner, guideQuestion }`. The tooltip shows the oneLiner
plus an "ask the guide" button that opens the panel and submits the
pre-seeded guideQuestion (e.g. raw toggle → "What does the raw view show
that the normal view hides?"). One structure feeds both the hover text
and the guide entry point, so control copy and guide knowledge can't
drift apart. The registry mechanism belongs in vg-core (new api seam,
e.g. `api.askAbout(topicId)`); the registry CONTENTS are per-app adapter
data. Propose the seam shape before implementing, per core policy.

## Tour (first-day steps; SHOW targets in app terms)

1. Welcome + the one-sentence premise: "this model writes stories, and
   this instrument shows what it's thinking before it says it."
2. Panel 2: pick a starter chip (use a hide/secret-class starter, NOT a
   two-line prompt — expectation-setting), press analyze.
3. Panel 3: click a word mid-story. Point at panel 4 appearing.
4. Panel 4: read one L7 row aloud; explain disposed-to-say; switch to
   DIFF; "green words are its secret plans."
5. Heat ritual: ask the player to click a promising chip (e.g. " hid");
   watch the story light up; ask "where did it decide?"
6. Panel 5: the moat story as narration; then invite one swap with the
   suggested pair; walk the three panes left to right.
7. Close: raw toggle as "the honest view", pink fragments, and "the lens
   gets smarter the longer your story gets — try your own."

## Adapter interface answers (per voice-guide-prompt-v3 seams)

- Verb table (all story/state-moving verbs gated to explicit request, per
  standing policy; validity-before-asking in core): ANALYZE(text),
  GENERATE, STOP, SELECTTOKEN(pos), SETMODE(J|logit|DIFF), TOGGLERAW,
  TOGGLETOP20, HEAT(word), SETSWAP(src,tgt,l0,l1,strength), SWAP —
  SWAP itself ratifies like First Day's ATTACH did (consent-scope lesson:
  offering to fill the swap boxes is not consent to press the button).
- statusText(): loaded-files state; story text + token count; selected
  token (piece + position); mode; raw/top-20 flags; heat word if any;
  swap config; last timings (analyze ms, dict cache hit). Serialize
  compactly — it grounds every Q&A answer.
- systemPrompt(): app's glossary above verbatim, plus the model-facts:
  stories110M, 12 layers (5 shown), TinyStories world, ~5k story vocab.
- Layout: two-column app; panel on the right below the readout at
  narrow widths; map palette from the app's CSS vars (--ink, --edge,
  --blue, --green, --pink, --gold — they exist; no dark-fallback risk).
- Takeover: pointerdown + keydown (not keyboard-heavy).
- Keyless chain per standing policy; mic policy core-owned.
- Deliverable stays ONE html file; core spliced at build time; smoke
  suite green twice, PASS count quoted as fingerprint.

## Carried forward to check live

- Guide must never press "swap & rewrite" unbidden (ratification), and
  must not treat "please do" after offering to FILL the boxes as consent
  to RUN the swap.
- The tour's step 5 depends on a story where the heat ritual pays off —
  ship 2–3 curated starters whose mid-band content is known-good (vase/
  hiding, dark-night/investigate, digging/hole) rather than trusting
  arbitrary player prompts on the first run.
- Panel 4 is dense; verify spotlight geometry on the layer rows at
  ~1300px and ~600px.

## Open decisions (Ken)

1. Mascot/persona — distinct from other apps' guides; something
   observatory/microscope flavored?
2. Slider rename: "surprise" or alternative.
3. App's real name (still placeholder "J-Lens Explorer").
