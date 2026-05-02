# Symbiotic Evolution App — Improvements

I'm attaching `symbiotic-evolution_v2.html`. Please make the following changes. The motivation for each is given so you can resolve any ambiguity in favour of intent. Keep the app a single self-contained HTML file.

---

## 1. Improve the LLM cross-evaluation analysis

**Problem:** The current single-prompt design asks the LLM to evaluate each organism *and* write an "Evolutionary Analysis" section as one combined response, which results in the experiment-level analysis being repeated (with minor rewording) inside every organism's evaluation. The synthesis is also uniformly positive and doesn't compare organisms to each other or notice when the Pareto front has collapsed onto one phenotype.

**Solution:** Split into two prompts.

### Prompt A — Per-organism aesthetic eval (called once per top organism)

Replace the existing per-organism prompt with one that asks ONLY for visual analysis. No mention of fitness trajectories, integration stats, or operator effects in this prompt. The model should respond with:

- Visual complexity (1–10) — what specifically creates the complexity in *this* image
- Aesthetic interest (1–10) — what works and what doesn't, comparing this organism's *visual character* to the other top organisms when relevant (the prompt should pass thumbnail labels of the others: "this is organism 3 of 5; the others are described as: [one-sentence visual descriptions of each]")
- A 1-sentence "phenotype tag" (e.g. "dense yellow lattice on blue", "sparse radial spokes", "concentric pulsing rings") — these tags get reused in Prompt B
- (If CLIP active) Prompt match (1–10)

Target response length: 80–120 words per organism. Drop the "evolutionary connection" sentence — that belongs in Prompt B.

The phenotype tag should be parseable: ask the model to format it as `**Phenotype:** <2–6 word tag>` so we can extract it programmatically with a regex.

### Prompt B — Experiment-level synthesis (called once, after all per-organism evals complete)

A separate API call that receives:

- All summary stats (current `fitnessTrend`, `integrationContext`, operator counts, sweep context)
- The list of phenotype tags extracted from Prompt A responses, paired with composite scores
- Pareto-front cardinality: count of *distinct* (entropy, color) coordinates among final-generation organisms (this number reveals collapse — see section 2 below)
- Diversity metric: distinct phenotype count from `APP.diversityHistory[last]`

The synthesis prompt asks for **four sections**, each clearly headed:

1. **Did evolution work?** — Is the fitness gain meaningful or could it be drift? Look at trajectory shape (sustained climb vs. early plateau). Note the percentage gain and whether the population converged or stayed exploratory.

2. **Symbiosis assessment** — Is the integration signal real? Specifically address: (a) is integration mean meaningfully above zero or just noisy positive, (b) does it grow with generation or stay flat, (c) are the same organism IDs reappearing in solo-fitness samples (which would inflate the percent-positive stat by repeated measurement of the same pair).

3. **Phenotype diversity** — Given the phenotype tags, are the top organisms variations on one theme or genuinely distinct strategies? Count distinct themes. If the top 5 share a phenotype tag, say so explicitly: "All 5 top organisms exhibit the same dense lattice phenotype — the search collapsed onto a single solution." This is the most important new piece of analysis.

4. **What's concerning or surprising** — Required section. The model must identify at least one weakness, anomaly, or unexpected pattern in the data, even if results are broadly positive. Examples: "the early-generation jump in best fitness suggests the seed was already near-optimal", "operator log shows DUPLICATE rarely fired — the search may have been mostly TUNE", "Pareto front contains only 3 distinct coordinates, suggesting fitness function collapse". If a sweep was run, also identify which condition under-performed and speculate why.

Tone instruction: explicitly tell the model "Be willing to say evolution didn't really work, or that the apparent symbiosis is an artifact, when the data supports it." The current prompt says "Be specific and critical. Not every organism is interesting." but the responses suggest this isn't strong enough — strengthen it to "Critical engagement is required. Sycophancy or vague praise is a failure of this task."

Target length: 250–400 words total across the four sections.

### Implementation notes for the LLM eval

- Prompt A runs in the existing per-organism loop. After it completes, parse `**Phenotype:** ...` tags from each response (regex match is fine).
- Prompt B runs after the loop. Render its result as a single block at the top of the results area (above the per-organism cards), with a heading "Experiment Synthesis" matching the existing card styling.
- If the user has stopped the eval mid-way, skip Prompt B (no data).
- Both prompts share the same provider/model/API key resolution as the current `runLMEvalCore`.
- Errors in Prompt B should display as a single error block — they should NOT prevent the per-organism evaluations from being shown.

---

## 2. Reduce phenotype collapse — improve the evolution algorithm

**Problem:** In actual experiment runs the Pareto front converges onto 3 or fewer distinct (entropy, color) coordinates and the top 5 organisms by composite score are visually near-identical (same dense yellow lattice on blue). The fitness function has correlated objectives, and existing diversity preservation (lineage cap, fitness sharing) is opt-in and easy to forget.

Make the following changes:

### 2a. Add NSGA-II crowding distance to the existing Pareto selector

Look at the `crowdingDistance` function around line 1756 — verify it's actually being used in selection. If selection currently does pure Pareto rank without breaking ties by crowding distance, add it. When the front contains more candidates than survivor slots, prefer the candidates with the largest crowding distance (i.e. the loneliest ones in objective space). This is a small change but the single biggest fix for "Pareto front with 3 distinct points being slowly populated by 16 near-duplicates."

If crowding distance is already in use, log a one-time console message confirming so I can verify.

### 2b. Add a behavioral novelty bonus (new feature)

Add a setting `noveltyWeight` (default 0.0, range 0.0–0.5) under the existing diversity controls in Setup.

When `noveltyWeight > 0`:
- Maintain `APP.behaviorArchive` — an array of organism phenotypes (small downsampled image fingerprints, e.g. 16×16 grayscale = 256 bytes per organism, plus generation born and ID).
- Each generation, after fitness is computed, also compute each organism's *novelty score*: mean image distance (MSE) from its k=15 nearest neighbours in the archive (or all of the archive if archive size <15).
- Cap archive size at 500. When full, evict oldest entries. Always keep current population.
- Modify the selection score: `effectiveScore = (1 - noveltyWeight) * fitnessScore + noveltyWeight * normalizedNoveltyScore`. Normalize novelty to [0,1] across the current generation before mixing.
- For Pareto mode, treat novelty as an additional objective (added to the metrics list internally during selection only — don't display it as a fitness metric in charts).

Add an info-button explanation: novelty search rewards being different from what evolution has *already explored*, not just from current peers. It often escapes local optima where fitness sharing alone fails.

### 2c. Make diversity controls visible on first run

Currently `lineageCap=0`, `fitnessSharing=false` and the new `noveltyWeight=0` are all off by default. Three off-by-default diversity mechanisms are easy to overlook.

Add a "Diversity preset" dropdown in the Setup tab with three options:
- **Off** — all three set to zero/false. (Current default.)
- **Mild** — lineageCap=3, fitnessSharing=true, noveltyWeight=0.0.
- **Strong** — lineageCap=2, fitnessSharing=true, noveltyWeight=0.2.

Keep the individual controls visible and editable; the dropdown is a shortcut. If the user manually edits any of the three after picking a preset, the dropdown should switch to "Custom".

Default the dropdown to **Mild** for new experiments. The current "Off" default means new users get phenotype collapse without realising why.

### 2d. Add parsimony as an optional fitness metric

Add a new metric `parsimony` to the metrics list, computed as `max(0, 1 - totalMBs/20)` where `totalMBs = a.ensemble.length + b.ensemble.length`. Higher = simpler ensemble.

Including parsimony alongside `spatial_entropy` and `distinct_colors` creates real Pareto tension (more MBs typically = more entropy/colors but lower parsimony), which is exactly what's missing from the current commonly-used metric pair.

Update the metric label dictionary and any UI dropdowns. Don't change default metrics.

### 2e. Strengthen TUNE perturbations (small)

Current TUNE adjusts `amount` by ±10–30%. Increase the upper bound to ±40% and add a 10% chance per TUNE event to make a "large jump": ±60–100% on amount only. This adds a small structural-search component without breaking the operator's identity. Comment the change.

---

## 3. Make sweeps easier to author and customise

**Problem:** Sweeps are powerful but hidden behind a JSON textarea. Customising a preset means understanding the schema, hand-editing JSON, and re-validating. New users won't author novel sweeps. The schema docs are minimal.

### 3a. Add a "Sweep Builder" UI alongside the JSON view

Above the existing textarea, add a collapsible "Builder" panel (default open for new users, remembers state). The Builder offers:

- Sweep name (text input)
- Generations, population size, ticks/eval (number inputs with sensible ranges)
- Seeds (multi-select chips: alpha, beta, gamma, delta, epsilon — pick any subset, default [alpha, beta, gamma])
- **Conditions** as a stacked card list. Each condition card has:
  - Name (text)
  - "Vary parameter" dropdown — pick which dimension this condition tweaks. Options correspond to override types: `pairing`, `boundary`, `metric pair`, `pareto on/off`, `operator rates (full)`, `single rate (couple/dup/tune/dissolve)`, `empPruneInterval`, `empPruneThreshold`, `survivorFrac`, `lineageCap`, `noveltyWeight`, `clip mode`, `ticksPerEval`.
  - When a parameter is picked, render the appropriate input widget (slider for rates and weights, dropdown for enums, number for integers, multi-select for metrics).
  - "Inherit baseline values" checkbox (default on) — when on, only the chosen vary-parameter is overridden; everything else uses the sweep-level defaults.
  - Up/down/duplicate/delete buttons per card.
- "+ Add condition" button at the bottom of the list.
- "Preview JSON" button — renders the equivalent JSON in the textarea below without running.
- "Apply to JSON" button — writes the Builder state into the textarea.
- The textarea remains the source of truth for `Run Sweep`. If the user edits JSON directly, the Builder shows a "JSON has been edited — reload Builder?" warning rather than silently overwriting.

This is a UI addition, not a replacement. Power users keep the textarea.

### 3b. Add new sweep presets

Add these to `SWEEP_PRESETS`:

- **`diversity_mechanisms`**: 4 conditions (no diversity, lineage cap only, fitness sharing only, novelty only at weight=0.2) — directly tests which diversity mechanism contributes most to phenotype variety. Run with seeds=[alpha,beta,gamma], 30 generations, 16 pop. Track distinct-phenotype count as the key signal.

- **`parsimony_pressure`**: 3 conditions (no parsimony, parsimony as 3rd Pareto objective, parsimony as scalar penalty `entropy + colors - 0.5*MBs`). Tests whether evolution finds smaller ensembles that achieve similar visual quality.

- **`fitness_landscape_breadth`**: 5 conditions, each using a different metric pair. The pairs should be chosen to maximize evolutionary divergence: (entropy, components), (symmetry, fractal_dim), (compressibility, coverage), (edge_density, distinct_colors), (parsimony, spatial_entropy). Different "habitats" produce different "species". Already partially covered by `metric_habitats` but this version is explicitly about evolutionary path divergence and uses 30 gens, 2 seeds (smaller cost).

- **`novelty_strength`**: noveltyWeight values 0.0, 0.1, 0.2, 0.3, 0.5 with all else equal. Find the sweet spot before novelty overrides actual fitness.

Each preset should have a clear `description` field explaining the *research question* it's designed to answer.

### 3c. Better schema documentation in the info modal

The current info modal for the sweep section lists overrides as a code-formatted run-on. Replace with a proper structured table: parameter name, type/range, default, one-line description. Include all newly added overrides (lineageCap, noveltyWeight). The schema doc should be the only place the user needs to look to write a sweep.

### 3d. "Total runs" estimator with cost warning

Above the Run Sweep button, show: `Total runs = conditions × seeds = N` and an estimated runtime based on `generations × populationSize × ticksPerEval × N` with a rough constant. If estimated runtime > 30 minutes, show an amber warning. If > 2 hours, show a red warning with a "Reduce seeds" suggestion.

---

## Constraints

- Single self-contained HTML file. Add code; do not split into multiple files.
- Match existing visual design (Chakra Petch headings, JetBrains Mono code/values, dark theme, teal/amber/lavender accents). New UI controls should look like existing ones.
- Don't break loading of older experiment JSON exports. Add migration logic if you change saved schema.
- Keep `noveltyWeight=0`, `parsimony` excluded from default metrics, and Builder UI (not JSON) defaulting to open for new users — i.e. nothing changes for someone re-loading an existing experiment.
- Comment new functions briefly. Don't refactor unrelated code.
- Test that the Diversity preset, sweep builder, novelty bonus, and split LLM analysis all work end-to-end before considering done.
