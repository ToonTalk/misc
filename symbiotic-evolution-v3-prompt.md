# Symbiotic Micro-Behavior Evolution — v3 Implementation Brief

Attached: `symbiotic-evolution_v2.html` (current, 6,384 lines, 295 KB).

This brief specifies four changes to the existing app. Implement all four. Output a single self-contained HTML file (same architecture as v2). **Do not refactor anything outside the touched regions** — every change is additive or replaces a clearly identified block.

---

## Change 1 — Novelty Search

**Why this change exists.** Experiments to date show populations converging onto a narrow band of phenotypes. The existing diversity mechanisms (`fitnessSharing`, `lineageCap`, `measureDiversity`) are corrective — they detect or mildly penalise convergence after it happens. Novelty search is generative: it actively rewards behaviours that nothing else in the population (or in the history of the run) has done. This is the missing ingredient for real visual variety.

**Concept.** A behaviour descriptor is computed for each organism. Novelty = average distance to the k nearest neighbours among (current population ∪ a persistent archive). Organisms whose novelty exceeds a threshold are added to the archive. Novelty can be used as: an additional Pareto objective; a scalar mixed with fitness; or as a sole objective (pure novelty search, fitness-blind).

### Behaviour descriptor

Reuse the 32×32 thumbnail rendering already used by `measureDiversity()` (line 1658). Convert the RGBA imageData into a fixed-length feature vector. Default: a **256-dim concatenated histogram** — 64-bin grayscale luminance histogram + 64 × 3 per-channel histograms — normalised to unit L1 within each sub-histogram. This is cheap, deterministic, and captures both spatial coverage and colour distribution without needing CLIP.

Make the descriptor function pluggable via `cfg.noveltyDescriptor`:
- `'histogram'` (default, above)
- `'pixels'` — raw 32×32×3 = 3072-dim flattened thumbnail, divided by 255
- `'clip'` — only available if CLIP is loaded; uses the CLIP image embedding (the model already runs in v2; reuse the pipeline). 512-dim, L2-normalised.

Distance metric: cosine distance for `clip` and `histogram`, Euclidean (mean-squared) for `pixels`.

### Novelty archive

- `APP.noveltyArchive = []` — array of `{ descriptor, generation, organismId }` entries. Persists across the run; not reset between generations.
- Cap at `cfg.noveltyArchiveMax` (default 500). When full, evict the oldest non-recent entry (FIFO over entries older than 5 generations; never evict entries added in the last 5 generations).
- After each generation's evaluation, score every organism's novelty against (current pop ∪ archive). If `novelty > cfg.noveltyAddThreshold` (default 0.15 for histogram, 0.08 for CLIP, 0.04 for pixels), add to the archive.

### Novelty score computation

```
novelty(org, others) = mean(top-k smallest distances from org.descriptor to each d in others)
```

Where `others = current_population_descriptors ∪ archive_descriptors`, excluding org itself. `k = cfg.noveltyK` (default 5). If `|others| < k`, use all of them.

### Three usage modes (`cfg.noveltyMode`)

1. **`'off'`** — novelty is computed and logged for diagnostics, but not used in selection. (Default.)
2. **`'objective'`** — novelty is added as an extra metric to the Pareto front. The metrics list already supports this pattern; treat novelty as if it were a metric named `'novelty'`. Works with `cfg.pareto: true`.
3. **`'scalar'`** — when ranking is scalar, mix into the composite score: `effective_score = (1 - α) * fitness_score + α * novelty_score`, where `α = cfg.noveltyWeight` (default 0.3). Both values normalised to [0,1].
4. **`'pure'`** — fitness is replaced entirely by novelty in selection. Useful as a control to show what evolution does when no fitness pressure is applied at all. The fitness metrics are still computed and logged for analysis; they just don't influence selection.

### Config additions to `APP.config`

```js
// Novelty search
noveltyMode: 'off',          // 'off' | 'objective' | 'scalar' | 'pure'
noveltyDescriptor: 'histogram', // 'histogram' | 'pixels' | 'clip'
noveltyK: 5,
noveltyWeight: 0.3,          // used in 'scalar' mode
noveltyAddThreshold: 0.15,   // used to decide if an organism enters the archive
noveltyArchiveMax: 500,
```

### Integration points

- After `evaluatePopulation()` (the existing fitness evaluator), call a new `evaluateNovelty()` that computes descriptors and novelty scores for every organism, attaches `org.descriptor` and `org.noveltyScore`, and updates the archive.
- In `rankPopulation()`: if `cfg.noveltyMode === 'objective'`, add `'novelty'` to the metrics list for that ranking. If `'scalar'`, mix as above. If `'pure'`, rank by novelty alone.
- Log per-generation: `APP.noveltyHistory.push({ gen, archiveSize, meanNovelty, maxNovelty, minNovelty })`.

### UI additions

Add a **Novelty Search** card in the Setup tab, beside or below the existing Diversity controls. Fields:
- Mode (dropdown: Off / Pareto objective / Scalar mixed / Pure novelty)
- Descriptor (dropdown: Histogram / Raw pixels / CLIP — last greyed out unless CLIP loaded)
- k (number input, 1–20)
- Weight α (slider, 0–1, only shown when mode = scalar)
- Add threshold (number, 0.001–1)
- Archive size cap (number, 50–5000)

Add a sparkline / line chart of `archiveSize` and `meanNovelty` over generations in the Results dashboard, beside the existing diversity sparkline.

### CSV / JSON export

Add fields per organism: `novelty_score`, `in_archive` (bool). Add per-generation: `archive_size`, `mean_novelty`. Don't break existing column order — append new columns at the end.

---

## Change 2 — Big-Picture LLM Analysis (Synthesis Pass)

**Why this change exists.** The current LLM analysis (`runLMEvalCore`, lines ~4150–4283) sends one API call per organism. Each call only sees one image and asks for that organism's score plus a "brief Evolutionary Analysis" — but since each call is independent, the supposed analysis is unanchored from the rest of the population. Result: lots of per-organism trivia, no big-picture story.

**Fix.** Restructure into two phases:

### Phase 1: Per-organism scoring (keep most of what exists)

Same as today, but **strip the "Evolutionary Analysis" section out of the per-organism system prompt**. Each call only does scoring + observation for its one organism. Collect the per-organism text into an array `APP.lmEvalPerOrganism = [{ id, score, text }, ...]`.

Shorten the per-organism prompt to focus only on the per-organism task:

> For the organism image provided, give:
> 1. Visual complexity (1–10) and what creates it
> 2. Aesthetic interest (1–10) with specific observations
> 3. Prompt match (1–10) if a CLIP prompt was specified
> 4. One sentence connecting what you see to the organism's metrics and lineage depth

Drop the request for evolutionary speculation at this stage.

### Phase 2: Synthesis call (new)

After all per-organism calls complete, make **one additional API call** with:
- **Image input**: a single composite collage image of all N organism thumbnails arranged in a grid (3 or 4 columns, organism IDs as small labels under each). Build this client-side from the rendered canvases; pass as one base64 PNG.
- **Text input**: a structured summary containing:
  - The same evolutionary context block already constructed (metrics, fitness trend, integration, operator counts, CLIP, sweep)
  - A condensed list of the per-organism scores from Phase 1 (just the numbers and a one-line abstract per organism — not the full text)
  - Population-level diagnostics: archive size, mean novelty, distinct-organism count, fitness-sharing penalties applied, mean lineage depth, generations elapsed
  - If a sweep ran, per-condition aggregate stats (best, mean, integration mean, novelty mean)

System prompt for the synthesis call:

> You are a senior research scientist analysing the results of an evolutionary art experiment. You see a grid of the top organisms produced by the run, alongside structured statistics about the population and (if applicable) the parameter sweep that produced them.
>
> Your job is to write a **single coherent analytical narrative**, not a list of scores. Target length: 400–700 words. Structure:
>
> 1. **What this population converged on** — 1 paragraph. Describe the visual character of the top organisms as a *group*, not individually. What aesthetic strategy did evolution find? What's the dominant motif?
> 2. **Diversity and convergence** — 1 paragraph. Is the population visually unified, partitioned into clusters, or scattered? Reference the diversity metrics and novelty archive. If a sweep was run, note which conditions produced the most distinct outcomes.
> 3. **Evolutionary mechanics** — 1 paragraph. What does the operator log and integration trajectory suggest? Did COUPLE seem to do real work (look for integration > 0), or did organisms behave near-additively? Was there evidence of co-adaptation between the two turtles?
> 4. **Notable individuals** — at most 3 bullet points, each naming an organism by ID and saying *why* it stands out *relative to the others in the grid*. No bullet points for "this one is the highest-scoring" — that's already in the data.
> 5. **One critical observation** — 1–2 sentences. What's *not* working, or what looks suspicious. Be direct; the user wants critique, not praise.
>
> Do not repeat the per-organism scores. Do not list everything by row. Write like a scientist briefing a colleague, not a captioner.

Render the synthesis output as a top-block in the LLM Analysis results, **above** the per-organism details. Add a button to copy the synthesis text alone (for use in research notes).

### Cost-control switches

- A checkbox "Run synthesis pass" in the LLM Analysis UI (default on).
- A token estimate displayed before running — synthesis adds roughly one call's worth of tokens, plus the composite image (~one extra image).
- If `topN > 12`, build the collage as 4-column × ceil(topN/4)-row grid; if `topN > 20`, downsample each thumb to 96×96 instead of 128×128 to keep the composite manageable.

### Implementation notes

- Build the collage by drawing each rendered organism canvas into one large canvas, then `.toDataURL('image/png')`.
- Use the same provider/model/key as the per-organism phase. (Don't add new auth UI.)
- For the in-artifact provider path (`provider === '_artifact'`), the synthesis call should also go through `claude-sonnet-4-20250514` — same as the per-organism calls.
- Save the synthesis text into `APP.lmEvalSynthesis` so the JSON export includes it.

---

## Change 3 — Preset Improvements

The current `SWEEP_PRESETS` object (line 4421) has 14 presets, all reasonable but written before novelty search existed and before we knew low visual variety was the central failure mode.

### Add four new presets

```js
novelty_vs_fitness: {
  name: 'Novelty Search vs Fitness-Only',
  description: 'Does novelty search produce more visual variety than fitness pressure alone? Four conditions compare off, pareto-objective, scalar-mixed, and pure novelty search.',
  seeds: ['alpha', 'beta', 'gamma'],
  generations: 50, populationSize: 16, ticksPerEval: 600,
  conditions: [
    { name: 'Fitness only (control)',
      overrides: { noveltyMode: 'off', metrics: ['spatial_entropy', 'distinct_colors'], pareto: true } },
    { name: 'Novelty as Pareto objective',
      overrides: { noveltyMode: 'objective', metrics: ['spatial_entropy', 'distinct_colors'], pareto: true } },
    { name: 'Scalar 30% novelty',
      overrides: { noveltyMode: 'scalar', noveltyWeight: 0.3, metrics: ['spatial_entropy', 'distinct_colors'], pareto: false } },
    { name: 'Pure novelty (fitness ignored)',
      overrides: { noveltyMode: 'pure', metrics: ['spatial_entropy', 'distinct_colors'] } }
  ]
},

novelty_descriptor_choice: {
  name: 'Novelty Descriptor Comparison',
  description: 'Does the choice of behaviour descriptor matter? Compare histogram, raw-pixel, and (if available) CLIP descriptors at fixed novelty weight.',
  seeds: ['alpha', 'beta'],
  generations: 40, populationSize: 16, ticksPerEval: 600,
  conditions: [
    { name: 'Histogram descriptor',
      overrides: { noveltyMode: 'objective', noveltyDescriptor: 'histogram', metrics: ['spatial_entropy'], pareto: true } },
    { name: 'Raw pixel descriptor',
      overrides: { noveltyMode: 'objective', noveltyDescriptor: 'pixels', metrics: ['spatial_entropy'], pareto: true } },
    { name: 'CLIP descriptor (requires CLIP loaded)',
      overrides: { noveltyMode: 'objective', noveltyDescriptor: 'clip', metrics: ['spatial_entropy'], pareto: true } }
  ]
},

diversity_stack: {
  name: 'Diversity Mechanisms Stacked',
  description: 'Which diversity mechanism actually helps? Compare each in isolation and stacked. Measures both score AND distinct-organism count.',
  seeds: ['alpha', 'beta', 'gamma'],
  generations: 50, populationSize: 16, ticksPerEval: 600,
  conditions: [
    { name: 'None',
      overrides: { fitnessSharing: false, lineageCap: 0, noveltyMode: 'off', metrics: ['spatial_entropy', 'distinct_colors'] } },
    { name: 'Fitness sharing only',
      overrides: { fitnessSharing: true, lineageCap: 0, noveltyMode: 'off', metrics: ['spatial_entropy', 'distinct_colors'] } },
    { name: 'Lineage cap only',
      overrides: { fitnessSharing: false, lineageCap: 3, noveltyMode: 'off', metrics: ['spatial_entropy', 'distinct_colors'] } },
    { name: 'Novelty only',
      overrides: { fitnessSharing: false, lineageCap: 0, noveltyMode: 'objective', metrics: ['spatial_entropy', 'distinct_colors'] } },
    { name: 'All three stacked',
      overrides: { fitnessSharing: true, lineageCap: 3, noveltyMode: 'objective', metrics: ['spatial_entropy', 'distinct_colors'] } }
  ]
},

long_novelty_run: {
  name: 'Long Novelty Run (100 generations)',
  description: 'Does novelty search keep producing new things, or does the archive saturate? Single condition, single seed, 100 generations. For diagnostic plotting of archive growth and mean novelty over time.',
  seeds: ['alpha'],
  generations: 100, populationSize: 24, ticksPerEval: 600,
  conditions: [
    { name: 'Long novelty objective',
      overrides: { noveltyMode: 'objective', noveltyArchiveMax: 1000, metrics: ['spatial_entropy', 'distinct_colors'], pareto: true } }
  ]
}
```

### Update existing presets — add a novelty default

For the existing `baseline` preset only, set `noveltyMode: 'objective'` in its overrides. Document this in its description: "Reference run with novelty search active as Pareto objective." This makes the default-baseline a stronger baseline.

Leave the other existing 13 presets unchanged (they're useful exactly as written for studying operators without novelty as a confound).

---

## Change 4 — Easier Sweep Customisation

The current sweep UI requires editing raw JSON in a textarea. This is fine for power users but is hostile to iteration. Two changes:

### A. Sweep persistence in localStorage

- Add three buttons next to the existing "Load preset →" button:
  - **Save as new preset** — opens a small inline prompt for a name, then saves the current textarea contents (validated as JSON first) to `localStorage['sweep_presets_user']`. User presets appear in the dropdown under a separator labelled "─── My presets ───".
  - **Duplicate** — loads the currently selected preset into the textarea with " (copy)" appended to its name, ready for editing. Does not save automatically.
  - **Delete preset** — only enabled when a user preset is currently selected. Removes from localStorage and the dropdown after confirmation.
- User presets must not be allowed to overwrite built-in preset keys. Force unique keys with a suffix if needed.
- Built-in presets remain read-only (no delete option when one is selected).

### B. A simple "knobs" view alongside raw JSON

Add a tab toggle at the top of the sweep section: **Form view** | **JSON view**. Default to Form view.

The Form view shows, for the currently loaded preset spec:
- `name`, `description` — text inputs at top.
- `seeds`, `generations`, `populationSize`, `ticksPerEval` — simple inputs.
- **Conditions** — each condition rendered as a collapsible card showing:
  - Name (text input)
  - Override entries as `key: value` pairs, each editable, with a + button to add a new override and a × to remove. Provide a dropdown of common keys (`rates.tune`, `rates.couple`, `rates.dup`, `rates.dissolve`, `pairing`, `boundary`, `pareto`, `metrics`, `noveltyMode`, `noveltyDescriptor`, `lineageCap`, `fitnessSharing`, `empPruneInterval`, `clip.enabled`) — but free-text key entry is still allowed.

Both views are bidirectional: edits in the Form view immediately update the JSON in the JSON view, and vice versa. The "Validate" and "Run Sweep" buttons read from whichever view is currently visible (always serialise via the underlying JSON model).

Keep the Form view minimal — this is a convenience layer over JSON, not a replacement. If a preset uses nested structures the form doesn't handle gracefully (deeply nested CLIP configs, etc.), show those overrides as raw JSON in a collapsible "Advanced overrides" sub-section within the condition card.

### Don't break the existing JSON workflow

The textarea, validation, run, cancel, and clear functionality all remain. The toggle just adds a friendlier surface on top.

---

## Build order

Implement in this sequence so each stage is independently testable:

1. **Novelty Search core** — descriptors, archive, novelty scoring function. Verify by logging novelty values per organism in the console even when `mode === 'off'`.
2. **Novelty integration into selection** — wire into `rankPopulation` for all four modes. Run the `novelty_vs_fitness` preset end-to-end and verify the four conditions produce visibly different outputs.
3. **Novelty UI and history charts** — config knobs, sparkline of archive size.
4. **New presets** — add the four new preset blocks.
5. **Synthesis LLM pass** — extract the per-organism prompt change, build the composite image, add the synthesis call, render the synthesis block above the per-organism blocks.
6. **Sweep persistence** — localStorage save/duplicate/delete.
7. **Sweep form view** — the form/JSON toggle.

Stop after step 2 and confirm visually that the variety problem is fixed before proceeding. If novelty search doesn't visibly broaden the phenotype distribution, the rest of the build is in danger of fixing the wrong thing.

---

## Things not to touch

- The micro-behavior data model and tick engine.
- The renderer (`renderPair`).
- The existing operators (TUNE / COUPLE / DUPLICATE / PRUNE / DISSOLVE / FORM) and their probabilities — only the *selection* side changes.
- The "no crossover" rule. (Novelty search does not introduce crossover; it only changes which organisms get to reproduce.)
- The `paretoFronts` function — it's correct; we just feed it an extended metrics list.
- CLIP integration — reuse the loaded pipeline for the optional `'clip'` novelty descriptor, but don't restructure how CLIP fitness works.

---

## Deliverable

One file: `symbiotic-evolution_v3.html`. Single-file, self-contained, drop-in replacement for v2. Same overall architecture, same visual theme, same tab structure. Note in the help/info pane that this is v3, with a line about novelty search being the headline addition.
