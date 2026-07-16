# Brief: Fit and evaluate Jacobian lenses on TinyStories models

## Purpose

Decisive feasibility experiment for a planned kid-facing, fully in-browser
J-lens app (a fourth Tiny Mind app). Question to answer: **does a 12-layer,
whole-word-register TinyStories model (stories110M) produce mid-layer J-lens
readouts that are (a) legible to a middle-schooler and (b) not reproducible
by a plain logit lens?** Secondary: how much worse is the 6-layer stories15M,
and does fitting on TinyStories text beat the standard web-text corpus?

Everything runs locally. No conclusions are needed from you beyond the
artifacts below — the human evaluates legibility.

## References (read before coding)

- Paper: https://transformer-circuits.pub/2026/workspace/index.html
- Reference implementation: https://github.com/anthropics/jacobian-lens
  (Apache-2.0). **Read the `jlens/fitting.py` module docstring first** — it
  documents the exact estimator (cotangents summed over current-and-future
  target positions, averaged over source positions). Report the measured
  fitting cost early so budgets can be adjusted.
- Lens definition: `lens_l(h) = unembed(J_l @ h)`, `J_l = E[∂h_final/∂h_l]`.
  One d×d matrix per layer. Official fits used 1000 seqs × 128 tokens of
  pretraining-like text; quality reportedly saturates fast (~100 prompts usable).
- Pre-fitted lens format examples: https://huggingface.co/neuronpedia/jacobian-lens

## Step 0 — Environment

- Python + PyTorch (GPU if available; CPU acceptable at these scales).
- `pip install git+https://github.com/anthropics/jacobian-lens`
- Smoke-test with the repo's `walkthrough.ipynb` flow on any tiny HF model
  before touching the real targets.

## Step 1 — Models

Targets (Karpathy TinyStories Llamas):
- **stories110M**: dim 768, 12 layers, 12 heads, seq 256, Llama-2 arch, 32K
  Llama tokenizer.
- **stories15M**: dim 288, 6 layers, 6 heads, seq 256, same tokenizer.

`jlens.from_hf` expects a HuggingFace decoder. Try
`Xenova/llama2.c-stories110M` and `Xenova/llama2.c-stories15M` first —
verify they exist, match the configs above, and produce fluent output. If
absent or mismatched, convert `karpathy/tinyllamas` checkpoints
(`stories110M.pt`, `stories15M.pt`) to `LlamaForCausalLM` yourself; the
weight layout is documented in `karpathy/llama2.c` (`export.py` is the map).

Sanity gate: greedy completion of "Once upon a time" must be fluent
TinyStories prose on both models before any fitting.

## Step 2 — Fits (three lenses)

| id | model       | fit corpus                        |
|----|-------------|-----------------------------------|
| A  | stories110M | TinyStories (`roneneldan/TinyStories`), 128-token seqs |
| B  | stories110M | WikiText-103, 128-token seqs (control — the official-recipe corpus) |
| C  | stories15M  | TinyStories, 128-token seqs       |

- Start at 100 prompts each; if a fit is cheap (<~30 min), rerun at 1000 and
  keep both. Use `checkpoint_path`; save every lens (`lens.pt`) with a config
  JSON (model revision, corpus, n_prompts, seq_len, wall-clock, hardware).
- Record wall-clock per fit prominently — it feeds a later decision about
  in-browser (WebGPU) fitting feasibility.

## Step 3 — Evaluation artifacts

For each lens, and for the logit lens as baseline, run this eval set
(teacher-forced; read all layers; also render the repo's slice-page HTML):

1. "Once upon a time there was a little girl named Lily. She had a dog named Max. One day"
2. "Tom saw a big dark cloud in the sky. He kept playing outside."
3. "Sara put her red ball in the box. Then she went to eat lunch. When she came back"
4. "Ben broke his mom's favorite vase. He heard her coming."
5. "Anna was very hungry. She looked in the kitchen and saw an apple, a banana, and a cake."
6. "The little bird could not fly. Every day it tried and tried."
7. "First Anna put on her socks, then her shoes, then"
8. "Lily and Max went to the beach. Lily built a castle. Max dug a"
9. "It was a dark night. Tim heard a strange noise in the garden."
10. "Mia planted a tiny seed. She watered it every day. After many days"
11. "The dragon was not mean. He was just lonely."
12. "Sam had three cookies. He gave one to his sister."

Display filter (apply everywhere): keep only leading-space alphabetic tokens
(word-starts); drop punctuation and continuation fragments. Report raw top-k
separately in an appendix so the filter's effect is visible.

Produce `report.md` with:
- Per prompt × layer band: top-8 filtered J-lens readouts vs top-8 logit-lens
  readouts at the SAME layers, plus a DIFF column (high under J, absent under
  logit).
- A layer-divergence curve per model: rank correlation (or top-k overlap)
  between J-lens and logit-lens readouts by layer — where and how much they
  diverge.
- A vs B: does the TinyStories-fit lens give cleaner readouts than the
  WikiText-fit lens on the eval set? Show 3 side-by-side examples.
- A vs C: 110M vs 15M on identical prompts — 3 side-by-side examples.
- The Lily check: on prompts 1 and 8, does the fragment token " L" (and
  "ily") light up mid-layers when Lily is the active character? Note every
  case where a multi-token name is readable only via its first piece.
- Wall-clock table for all fits.

## Acceptance criteria

1. All three fits complete without NaNs; lenses apply cleanly at all layers.
2. Both models pass the fluency gate.
3. `report.md` answers, with examples: at which layers does the J-lens show
   content the logit lens lacks; is the divergence larger at 110M than 15M;
   does in-register fitting (A) beat the control (B).
4. Deliverables: three `lens.pt` + config JSONs, slice-page HTMLs for the
   eval set, `report.md`, appendix with unfiltered readouts, and a
   `repro.sh` that regenerates everything from a clean checkout.

## Cautions

- Do not evaluate arithmetic — these models cannot do it, and a lens cannot
  read a computation that isn't happening. Narrative memory, character
  binding, foreshadowing, and sequence anticipation are the point.
- Fitting corpus note: for TinyStories models, TinyStories IS the
  pretraining-like corpus; that is why fit A exists and is expected to win.
- Mirror the official practice of reading mid-layer bands rather than the
  first or last layers; note the band you settle on per model.
- Pin seeds, dataset revisions, and model revisions. No silent retries with
  changed hyperparameters — log every deviation from this brief.
