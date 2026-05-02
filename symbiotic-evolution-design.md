# Symbiotic Micro-Behavior Evolution: Design Document

## Concept

A new browser-based research tool for exploring **symbiotic evolution** of micro-behavior ensembles — drawing on Blaise Agüera y Arcas's work on the role of combination (rather than mutation or sex) as a creative force in evolution. Each "organism" consists of two turtles, each driven by its own ensemble of micro-behaviors, sharing a canvas. Evolution proceeds through pairing of organisms, where parent ensembles **maintain their identity** (no genetic mixing, no crossover) and novelty emerges through inter-turtle interaction behaviors.

This is a separate app from the existing Micro-Behavior Composer. The Composer is for hand-crafted interactive exploration; this is for batch evolutionary experiments. The two apps share the tick engine, canvas renderer, micro-behavior data model, and visual design.

---

## What to Copy from the Existing Micro-Behavior Composer

Reuse the following without modification (or with minimal extension):

- The micro-behavior data model (`MicroBehavior`, `Action`, `Condition`)
- The tick execution loop (state update, condition evaluation, action application)
- The canvas renderer (line drawing, alpha, pen width handling)
- The boundary behavior options (wrap, bounce, clamp, ignore)
- All CSS and visual styling (Chakra Petch headings, JetBrains Mono code, dark theme, teal/amber/lavender palette)
- The starting state model
- Image rendering to PNG (`canvasB64()` style)

The existing composer's `APP.turtles` is already an array (single-element), so the multi-turtle extension is structural rather than a rewrite.

---

## Multi-Turtle Extension

### Architecture

An organism has 2 turtles. Each turtle has:

```
Turtle {
  id: 0 | 1                    // turtle index within organism
  state: TurtleState            // position, heading, color, etc.
  ensemble: MicroBehavior[]     // its assigned ensemble
  startingState: TurtleState    // for reset
}
```

The organism is `{ turtles: [Turtle, Turtle] }`. All turtles draw to the same canvas.

### Default starting positions

The two turtles must start at different positions or headings, otherwise they'll draw identical paths and never interact meaningfully. Defaults:

- Turtle 0: position (canvas_center_x - 50, canvas_center_y), heading 0
- Turtle 1: position (canvas_center_x + 50, canvas_center_y), heading 180

These are configurable per organism.

### New Inter-Turtle Condition Variables

In addition to the existing condition variables (`x`, `y`, `heading`, `r`, `g`, `b`, `a`, `bgR`, `bgG`, `bgB`, `penWidth`, `tick`), add:

- `dist_other` — Euclidean distance to the other turtle in this organism
- `bearing_other` — rotation in degrees relative to current heading needed to point at the other turtle. Range -180 to +180. 0 means "directly ahead", 180 (or -180) means "directly behind", -90 means "to the left", +90 means "to the right".

These use turtle-native geometry rather than absolute Cartesian coordinates. A condition like `{variable: 'bearing_other', operator: '<', value: 30}` fires when the other turtle is roughly in front (within 30° of straight ahead). A condition like `{variable: 'dist_other', operator: '<', value: 50}` fires when the turtles are close.

### New Action Types

Add two new action types alongside the existing ones:

- `+TOWARD` — rotate heading by `amount` degrees toward the other turtle. Positive amount means rotate toward; negative means rotate away. The amount cannot exceed the magnitude of `bearing_other` (so a "TOWARD 90" never overshoots). 
- `+AWAY` — equivalent to `+TOWARD` with negated amount, included for clarity.

These let evolution discover following, avoiding, orbiting, mirroring, predator-prey patterns without the user having to express them through Cartesian conditions.

### Tick Execution for Multi-Turtle

Each tick:

1. Save previous state for both turtles
2. Compute `dist_other` and `bearing_other` for each turtle (based on current state, before any updates)
3. For each turtle, evaluate its ensemble's conditions and apply firing behaviors' actions to *that turtle's* state
4. Apply boundary behavior, render the new line segment for each turtle
5. Advance tick counter

Conditions on each turtle reference *that turtle's* state. `dist_other` and `bearing_other` from turtle 0's perspective give distance/bearing to turtle 1, and vice versa.

---

## Population and Pairing Model

### Population

A population is an array of **single-turtle ensembles**. Each ensemble is a list of micro-behaviors. The population is the breeding pool from which organisms are formed.

```
Population {
  individuals: Individual[]
  generation: number
}

Individual {
  id: string
  ensemble: MicroBehavior[]
  startingState: TurtleState
  birthGeneration: number
  lineage: string[]            // ancestor IDs
  soloFitness: FitnessScores | null   // fitness when run alone, may be cached
}
```

### Pairing into organisms

To evaluate an individual, it must be paired with another into a 2-turtle organism. Two pairing strategies, user-selectable:

- **Stable lineages** (default): pairs are formed once and persist across generations. Each pair evolves as its own organism. The "individual" effectively *is* a pair from the organism's perspective. New pairs are formed at population initialization and through composition operators.

- **Open pairings**: every generation, individuals are randomly paired into organisms. Same individual may pair with different partners across generations. Better exploration, weaker integration signal.

For the first version, implement stable lineages. Add open pairings as a configurable option.

### Initial population

User specifies population size (default 16). The app generates initial ensembles via:

- **Random generation** (fastest, most diverse): random ensembles using the same parameter ranges as the Composer's "Random ensemble" feature
- **LLM generation** (optional): if the user provides API keys, prompt an LLM to generate diverse interesting ensembles. The LLM is only used here, not for fitness evaluation.

Once individuals exist, pair them into organisms using the chosen pairing strategy.

---

## The Six Composition and Variation Operators

All operators preserve parent identity. There is **no crossover** — no operator mixes micro-behaviors from two different ensembles into a single ensemble. Within-ensemble novelty arises through DUPLICATE followed by TUNE (the gene-duplication-and-divergence pattern from real biology). Between-ensemble novelty arises through COUPLE (new inter-turtle interaction behaviors). Genetic material from two different ensembles never blends.

### 1. FORM

Take two unpaired individuals A and B from the population, pair them into a 2-turtle organism. A's ensemble drives turtle 0; B's drives turtle 1. Both parents survive intact in the new organism.

### 2. COUPLE

Add an inter-turtle interaction behavior to one of the turtles in an existing organism. The new behavior must reference `dist_other` or `bearing_other` in its condition, or use `+TOWARD` / `+AWAY` as its action. Examples:

- `+TOWARD 5` (when dist_other > 80): a weak attractor that engages only when far apart
- `+RT 10` (when bearing_other < 20): turn right when partner is in front (avoidance)
- `+R 3` (when dist_other < 30): redden when close (proximity coloring)

The COUPLE operator is the primary source of *new* genetic material in symbiotic evolution. The LLM (if available) or a random generator can propose the new interaction behavior. If using random generation, draw the action and condition from the inter-turtle primitives weighted toward likely-interesting patterns.

### 3. DUPLICATE

Copy an existing micro-behavior within one ensemble, with small parameter variations applied to the copy. The copy is initially nearly redundant — it produces almost the same effect as the original. This is modeled directly on **gene duplication** in biology, which is the principal source of novel functions within a lineage without requiring sex or crossover.

The variation applied to the copy:
- `amount` perturbed by ±5–15%
- `amountDelta` perturbed by a small absolute amount
- `amountMultiplier` perturbed by ±0.005–0.02
- 30% chance to perturb one condition's `value` by ±10–20%

The copy joins the same ensemble as the original. Both behaviors persist; subsequent TUNE operations on either may differentiate them further. Over generations, the duplicate may:

- Specialize into a distinct role (e.g. an original fires unconditionally, the duplicate develops a condition that restricts it to certain phases)
- Become functionally absorbed by the original (parameters drift back toward identity), making both a Prune target
- Drift into something completely different from its parent

DUPLICATE is what makes the within-ensemble evolutionary cycle complete. Without it, ensembles can only grow via COUPLE (which adds inter-turtle behaviors) and otherwise stay structurally fixed under TUNE. With it, ensembles have a real mechanism for producing internal variation — and Prune has genuine work cleaning up the redundancy that emerges.

### 4. TUNE

Mutate parameters within an existing micro-behavior in one of the ensembles. Mutations:

- Adjust `amount` by ±10–30%
- Adjust `amountDelta` by a small absolute amount
- Adjust `amountMultiplier` by ±0.01–0.05
- Adjust a condition's `value` by ±10–30%
- Toggle `enabled` on/off

Does not change action types, add or remove behaviors, or move behaviors between turtles. TUNE is the slow specialization engine that operates on whatever DUPLICATE and COUPLE have introduced.

### 5. PRUNE

Remove redundant behaviors using two methods, applied in order:

**5a. Static pruning** (cheap, safe):

For each ensemble, scan for behaviors that can be algebraically merged or cancelled.

*Merge condition*: two behaviors can merge into one if all of:
- Same action type
- Same conditions (compared as sets, not ordered)
- Both have `amountMultiplier == 1` (or both have identical multipliers AND identical amounts — uncommon but legal)

When mergeable, replace both with a single behavior whose `amount = a1 + a2` and `amountDelta = d1 + d2`.

*Cancellation*: two behaviors with identical conditions but inverse action pairs cancel to nothing:
- `+FD N` and `+BK N` → both removed (or, if amounts differ, replace with the residual)
- `+RT N` and `+LT N` → similarly
- `+R N` and `+R -N` → similarly

DUPLICATE produces the bulk of static-pruning candidates: a duplicated behavior whose subsequent TUNE pushed its `amount` back toward the original's value will be a perfect merge target. Mutually cancelling pairs occur less commonly but can arise when a duplicated behavior's amount drifts to the negation of its parent's.

**5b. Empirical pruning** (expensive, approximate):

Render the organism for K ticks (default 200) to produce a reference image. For each behavior in each ensemble, render again with that behavior disabled, compute image distance from the reference (e.g. mean squared pixel difference). Behaviors whose removal produces image distance below a threshold (configurable, default 1% of total pixel variance) are candidates for removal.

Empirical pruning catches behaviors whose contribution has decayed below relevance — for example, a duplicated behavior whose `amount` has been tuned toward zero, or a behavior whose conditions have become so restrictive it almost never fires.

Apply empirical pruning every K generations (default every 5), not every generation — it's expensive.

Log every prune event with type (`static_merge`, `static_cancel`, `empirical_low_contribution`) and the affected behavior IDs. This produces an audit trail showing which operators are doing genuine work.

### 6. DISSOLVE

Split an existing 2-turtle organism back into its two component ensembles. Each component re-enters the population as a single individual, available for re-pairing in future FORM operations. The original organism is removed.

DISSOLVE plus FORM with new partners is how the population mixes lineages without genetic crossover. A successful component can be tested in many partnerships.

---

## Fitness Metrics

No LLM-based aesthetic judgment in the initial version. All fitness comes from objective metrics computed on the rendered image after K ticks.

### Available metrics

User selects one or more from this set:

| Metric | Computed from | Range | High value means |
|--------|---------------|-------|------------------|
| Spatial entropy | 16×16 luminance grid | 0 – ~5.5 | Visually complex, space-filling |
| Distinct colors | Unique RGB values in pixels (with quantization) | 0 – many | Color-rich |
| Edge density | Fraction of pixels at color boundaries | 0 – 1 | High contrast detail |
| Fractal dimension | Box-counting on binarized image | ~1 – ~2 | Scale-invariant structure |
| Connected components | Count of connected regions in binarized image | 0 – many | Fragmented |
| Compressibility | PNG file size / pixel count | varies | Algorithmic complexity proxy |
| Coverage | Fraction of pixels different from background | 0 – 1 | Filled canvas |
| Bilateral symmetry | Pixel-wise correlation between left/right halves | 0 – 1 | Symmetric |

### Multi-objective fitness

If the user selects multiple metrics, evolution uses Pareto-front selection rather than a scalar composite. An individual dominates another if it's at least as good on all metrics and strictly better on at least one. Selection picks from the non-dominated front first, then the second front, etc.

If the user selects a single metric, scalar selection (top-K) is used.

### The integration measurement

For each organism, periodically (default every 5 generations) also evaluate each component ensemble *alone* — run it as a single-turtle ensemble, compute the same fitness metrics. Store this in `Individual.soloFitness`.

The gap between paired fitness and solo fitness is the empirical signal of symbiotic integration. Track this gap across generations:

- Generation 0: components likely score similarly alone or paired (no integration yet)
- Later generations: if integration is happening, components should score lower alone than paired (specialization)

Plot this gap as a key result of any experiment.

---

## Evolution Loop

```
1. Initialize population of N single-turtle individuals
2. Pair into organisms (stable lineages by default)
3. For each generation:
   a. Evaluate fitness of each organism (render K ticks, compute metrics)
   b. Select organisms via Pareto-front (or top-K for single metric)
   c. For each surviving organism, apply each operator independently with its
      configured probability (operators may compose — multiple may fire on the
      same organism in one generation):
      - TUNE (default 50%) — slow specialization of existing behaviors
      - COUPLE (default 25%) — adds a new inter-turtle interaction behavior
      - DUPLICATE (default 10%) — copies an existing behavior with small variation
      - PRUNE static (every generation, automatic) — cleans algebraic redundancy
      - PRUNE empirical (every K generations, default 5) — cleans low-contribution behaviors
      - DISSOLVE (default 5%, applied to lowest-fitness organisms)
      - FORM (used after DISSOLVE to re-pair released individuals)
   d. Replace lowest-fitness organisms with offspring
   e. Periodically (every K gens): measure soloFitness for integration tracking
4. Stop when generation count reached, or fitness plateaus, or user stops
```

User controls: population size, generations, K (ticks per evaluation), operator probabilities, empirical pruning interval, integration check interval.

---

## UI Structure

### Tabs

**Tab 1: Setup** — define experiment parameters, select metrics, configure operator rates
**Tab 2: Run** — launch evolution, watch progress, see current best organisms
**Tab 3: Results** — fitness trajectories, Pareto front, integration tracking, organism gallery

### Setup tab

- Population size (default 16)
- Generations (default 50)
- Ticks per evaluation (default 1000)
- Pairing strategy (stable / open)
- Initial population source (random / LLM)
- API keys (only if LLM source selected)
- Fitness metrics (multi-select with weights for composite mode, or "Pareto" toggle)
- Operator rates (sliders or number inputs)
- Empirical pruning interval
- Integration check interval

### Run tab

- Progress bar (generation N of M)
- Current population summary (table of organisms with fitness scores)
- Live preview: a small canvas grid showing the top-3 organisms drawing in real time
- Stop button

### Results tab

- **Fitness trajectory chart**: best fitness per generation, plus mean and worst, for each metric
- **Integration chart**: paired-fitness minus solo-fitness over generations (the key symbiosis signal)
- **Pareto front visualization**: scatter of all organisms across two selected metrics, colored by generation
- **Organism gallery**: grid of canvases showing top organisms, clickable to expand into full detail (ensemble JSON, fitness scores, animation playback)
- **Operator log**: counts of how many times each operator fired, prune-event log
- **Lineage tree** (optional, can be added later): visual genealogy of organisms

---

## Data Export

JSON export of the full experiment:
- All organisms across all generations
- All ensembles (parents and offspring)
- Fitness trajectories
- Solo fitness samples
- Operator log
- Prune log
- Settings used

CSV exports:
- `organisms.csv`: one row per organism per generation, with fitness scores and parent IDs
- `operators.csv`: one row per operator firing event
- `integration.csv`: one row per solo-fitness measurement

PNG exports:
- A zip containing the rendered canvas of every organism in the final generation, named by lineage

---

## Build Phases

**Phase A: Multi-turtle tick engine and rendering** (foundation)
1. Copy the existing Composer's HTML/CSS/JS as the starting point
2. Refactor the tick loop to handle 2 turtles
3. Implement `dist_other` and `bearing_other` condition variables
4. Implement `+TOWARD` and `+AWAY` action types
5. Add a "two-ensemble preview" UI similar to the Composer but with two ensemble cards side-by-side
6. Verify by hand-crafting a simple chase pair and watching it draw

**Phase B: Image metrics and fitness evaluation**
7. Implement all listed image metrics as pure functions taking a canvas and returning a number
8. Build the Pareto-front selection routine for multi-metric fitness
9. Verify by computing metrics on hand-crafted examples

**Phase C: Population and operators**
10. Implement Population and Individual data structures
11. Implement initial population generation (random; LLM optional)
12. Implement each of the six operators (FORM, COUPLE, DUPLICATE, TUNE, PRUNE, DISSOLVE)
13. Implement static pruning (algebraic merge and cancel)
14. Implement empirical pruning (leave-one-out)
15. Implement the evolution loop with operator probabilities

**Phase D: Integration tracking and UI**
16. Implement solo fitness evaluation
17. Build the Setup tab
18. Build the Run tab with progress and live preview
19. Build the Results tab with charts and gallery
20. Implement JSON and CSV exports

**Phase E: Polish**
21. Lineage tree visualization
22. Animation export of the final organism
23. Any LLM-based features deferred to later

Build incrementally. Phase A should be standalone and testable before Phase B begins. Each phase produces a working app that does more than the previous phase.

---

## Visual Design

Match the existing Micro-Behavior Composer's design system: dark theme (with light mode toggle), Chakra Petch for headings, JetBrains Mono for values and code, teal/amber/lavender accent palette, card-based layout, rounded corners, subtle gradients. Title: "Symbiotic Micro-Behavior Evolution" with a subtitle like "Evolution by combination, not crossover."

---

## Key Design Principles to Preserve

1. **No crossover, ever.** Genetic material from two ensembles never mixes onto one turtle. The framework is committed to studying symbiosis specifically, not sex.
2. **Turtle-native geometry.** Inter-turtle relations use distance and bearing, not Cartesian deltas.
3. **Metric-driven fitness.** No LLM judgments in the evolution loop. The LLM may optionally contribute initial population diversity, nothing else.
4. **Identity preservation.** When two ensembles pair, both parents persist intact in the offspring organism. They can be dissolved back out and re-paired.
5. **Integration as the key empirical signal.** The gap between paired and solo fitness is the central measurement, because it's the empirical signature of symbiotic adaptation.
