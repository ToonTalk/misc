# Brief: Build the J-lens app prototype (Phase 1 — CPU, shipped lens)

## Purpose

A working prototype of a fourth Tiny Mind app (name: TBD by Ken; use
"J-Lens Explorer" as placeholder): a single-file, zero-dependency,
in-browser instrument that lets a middle-schooler watch what a TinyStories
model is "holding in mind" — per token, per layer — while it writes or
reads a story, and change those contents and see the story bend.

This phase is for evaluating the pedagogy, not shipping a product.
Explicitly OUT of scope for Phase 1: in-browser lens fitting, WebGPU,
model quantization, voice-guide integration, mobile. Those are Phase 2,
gated on Ken's evaluation of Phase 1.

## Inputs you will be given

1. `index.html` of the existing Tiny Mind app — reference for house style
   and, critically, source of modules to REUSE (do not reinvent):
   - `bin-reader.js` logic (llama2.c checkpoint parsing — it already
     handles arbitrary dims; stories110M.bin loads unchanged)
   - the SentencePiece tokenizer port (reads `tokenizer.bin`, vocab size
     from the checkpoint header)
   - the forward pass with tap hooks and the Capture pattern
   - the existing logit lens (needed as the comparison mode)
2. The `out/` directory from the fit-and-evaluate run:
   - `lenses/A/lens_1000.pt` + config (the lens to ship)
   - `lenses/C/lens_1000.pt` (15M lens — load-bearing only for Phase 2,
     but export it now while the tooling is open)
   - `eval/A/readouts.json` — GOLDEN FIXTURES for JS parity tests
   - `pins.json`, `corpora/*.json`
3. Model weights: `stories110M.bin` (fp32 llama2.c format, ~440 MB, from
   karpathy/tinyllamas on HF) + `tokenizer.bin`. App loads them via
   drag-drop (existing pattern) AND via URL fetch with a progress bar.

## Step 0 — Python-side prep (do this first)

a. **n-sweep** (informs Phase 2; cheap): fit stories110M/TinyStories at
   n ∈ {1, 5, 10, 25} (n=100 and 1000 exist). Report filtered top-8
   agreement at L4–L8 vs n=1000, per n, plus one slice page each for
   eval prompts 4 and 9. Also record wall-clock per fit.
b. **Lens exporter**: `lens_1000.pt` → `stories110M.jlens`, a little-
   endian binary: header (magic, version, d_model, layer list), then
   J_l as fp32 row-major 768×768 for layers 4–8 inclusive (~12 MB).
   Ship J only — the app derives readout dictionaries at load time from
   the model's own unembedding (see Step 2d). Same exporter, second
   file for the 15M lens (layers 2–3).
c. **Pruned-vocab + alias tables** (JSON, embedded in the app or
   sidecar): token ids observed in TinyStories train (threshold: count
   >= 5), expected ~3–6K ids; the word-start display mask; the
   multi-token-name alias table (first-piece -> display form, e.g.
   ` L` -> "L… (Lily?)") derived from names in the corpus; and a
   "lens-visible theme vocabulary" list (single-token story words) for
   the activity-prompt picker. MUST keep alias fragments in the pruned
   set even if below threshold.
d. **Golden fixtures**: for eval prompts 1, 4, 9: per position, per layer
   L4–L8, the top-20 token ids and scores for BOTH lenses, straight from
   the Python pipeline, as `fixtures.json`. The JS implementation must
   reproduce rankings (top-10 set overlap >= 0.9 per position-layer) —
   float noise tolerated, ordering-of-operations bugs not. The reference
   semantics for J-lens application (J, then final norm, then unembed —
   including where gamma sits) is WHATEVER THE PYTHON PIPELINE DID.
   Derive it from the jlens package source, not from memory.

## Step 1 — App skeleton

Single HTML file, no dependencies, no build step, Web Worker for compute
(existing pattern). Two ways to get a story in:
- **Analyze**: paste text (teacher-forced single forward pass, full
  capture).
- **Generate**: model writes from a prompt (streaming tokens, capture as
  it goes; temperature control; stop button).

## Step 2 — Compute path

a. **Fast CPU forward**: do NOT port the fround/C-parity discipline —
   that gate protects the 260K trainee, not this app. Use a blocked
   matmul (the Trainer's register-blocked version is the template).
   Target: full analysis of a 200-token story, all captures, in well
   under a minute on a desktop; report the measured number.
b. Skip full-vocab logit computation during capture except where the UI
   needs it (the unembedding is over half the per-token FLOPs).
c. **Capture**: residual stream at layers 4–8 (and the final layer) per
   position, reusing the Capture pattern.
d. **Readout dictionaries**: at load, per layer, compute
   D_l = W_U[pruned] · diag(gamma) · J_l  (~5K×768 per layer; ~6 GFLOPs
   per layer one-time — do it lazily per layer with progress). Then a
   readout at (layer, pos) is one D_l · h matvec (~7 MFLOPs) — this is
   what makes the UI real-time. The uniform RMS scalar doesn't change
   rankings; apply it only if displayed scores need calibration to match
   fixtures.
e. **Logit-lens mode**: same dictionary machinery with J = I.

## Step 3 — UI (instrument-first, no tutorial layer)

- **Story pane**: the text, one token selectable. Selecting a token sets
  the readout column.
- **Readout panel**: for the selected position, a layer strip (L4–L8):
  top-8 filtered readouts per layer, expandable to top-20; toggle
  J-lens / logit lens / DIFF (J-only tokens highlighted). Alias display
  for name fragments. Raw (unfiltered) view behind a toggle for honesty.
- **Heat view**: pick any token from the readout (e.g. ` hid`) and see
  its J-rank across ALL positions as a color strip under the story —
  "where was the model thinking this?"
- **Swap/inject**: choose a source word direction (from the pruned
  vocab), a target word, a layer range and position range, a strength
  slider (default LOW — small models oversteer), then regenerate from
  the edit point. Implemented as a residual-edit hook in forward,
  mirroring the existing ablate hooks. Show before/after stories side by
  side.
- Keep the visual idiom of the existing Tiny Mind apps.

## Acceptance criteria

1. Fixture parity: top-10 set overlap >= 0.9 vs `fixtures.json` for both
   lenses on all three prompts, all positions, L4–L8.
2. Analyze mode on a 200-token story completes with all captures in
   < 60 s on a typical desktop CPU (report the number; < 30 s is the
   stretch goal).
3. Readout panel updates in < 100 ms after token selection (post-capture).
4. Swap demo reproduces the expected qualitative result on eval prompt 8
   (swap ` hole`-adjacent content, story changes accordingly) — record a
   before/after pair in the README.
5. The n-sweep report from Step 0a is delivered alongside.
6. Deliverables: the app (one HTML file), `stories110M.jlens` +
   `stories15M.jlens`, sidecar JSONs, `fixtures.json`, a README with
   measured timings and known issues.

## Cautions

- Reuse the existing tokenizer/bin-reader/capture code; divergence there
  is where parity bugs will come from.
- The pruned dictionary must include punctuation/newline ids needed for
  correct tokenization even though they're display-masked.
- Do not add a framework, a bundler, or a CDN dependency. One file.
- Where the brief and the fixtures disagree, the fixtures win; log the
  discrepancy rather than "fixing" it silently.
