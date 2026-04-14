# Logo Evolution Lab — Analysis Brief

**Experiment ID:** `exp_1776149825154`  

**Created:** 2026-04-14T06:57:05.154Z  

**Status:** completed

## Research Question

This experiment tests whether LLM-driven iterative evolution of Logo turtle graphics programs produces results that significantly exceed what the same LLMs can generate in a single shot.

## Experimental Design

### Seed Programs

Each seed is a starting Logo program that evolution and Baseline B begin from:

**Spiral**

```logo
REPEAT 36 [FD 100 RT 170]
```

**Star**

```logo
REPEAT 8 [FD 120 RT 135]
```

### Aesthetic Taste Descriptions

These define what "better" means for each condition:
- `t3` — "Intricate asymmetric patterns with heavy use of color"

### Models
- **Evolution models** (generated variants and critiqued them): gemini-2.5-flash-preview-09-2025
- **Evaluation models** (cross-model judge, re-scored final programs): gemini-2.5-flash-preview-09-2025

### Parameters

| Parameter | Value | Notes |
| --- | --- | --- |
| Magnitude | 5 | Scale 1–10; higher = more drastic changes per iteration |
| Selection mode | deterministic | deterministic = always pick highest-scoring variant; roulette = score-weighted random |
| Critic mode | both | What the critic sees: both = images + code; images = images only; code = code only |
| Variants per iteration | 2 | Number of program variants generated each round |
| Iterations per run | 10 | Evolution steps per repeat |
| Repeats per condition | 3 | Independent evolutionary runs with same parameters (measures variance) |
| One-shot attempts | 10 | Baseline A/B attempts per condition (characterises one-shot distribution) |
| Base seed | 2890911 | For API reproducibility; deterministic seeds derived from this |
| Modifier temperature | 1 | API temperature for variant generation (higher = more diverse) |
| Critic temperature | 0 | API temperature for scoring (0.0 = deterministic evaluations) |
| Aesthetic weight | 1 | Multiplier for aesthetic component in composite score |
| Novelty weight | 2 | Multiplier for novelty component in composite score |
| Parsimony weight | 2 | Multiplier for brevity reward (0=disabled). Formula: max(0,10−commandCount/5) |
| Nesting encouraged | false | Whether modifier prompt includes nested REPEAT hint |

## Baseline Types

The experiment contrasts four conditions to isolate the contribution of each component:

**Baseline A (from scratch)** — `type=from_scratch` in baselines.csv  
The model writes the best Logo program it can given the taste description, with no seed program and no iteration. Run `oneshotAttempts` times per condition to characterise the one-shot distribution.

**Baseline B (single edit)** — `type=single_edit` in baselines.csv  
The model improves the seed program in one unconstrained step (equivalent to magnitude 10, 1 iteration). Run `oneshotAttempts` times per seed. Tests what one round of unconstrained improvement achieves.

**Baseline C (feedback only)** — `type=feedback_only` in runs.csv  
The full iteration loop, but `variantsPerIter=1`. Each iteration generates exactly one variant which automatically "wins" — there is no selection pressure, only the modifier-critic feedback cycle. If Evolution ≈ Baseline C, selection pressure adds nothing and the critic feedback is doing all the work.

**Evolution (full system)** — `type` absent or `evolution` in runs.csv  
The complete system: multiple variants generated each iteration, all scored by the critic, winner selected. Both feedback and selection pressure are active.

## Column Glossaries

### runs.csv

| Column | Description |
| --- | --- |
| condition_id | Unique identifier for the (seed × taste × model) combination, plus any sweep variant suffix |
| seed_label | Human-readable name of the seed program |
| taste | Full text of the aesthetic taste description |
| model | API model identifier used for both modifier and critic agents |
| repeat_index | Which repeat of this condition (0-indexed). Different repeats are independent runs with different seeds |
| iterations_completed | How many evolution iterations completed before stopping (may be < iterationsPerRun if run errored) |
| final_score | Total score (aesthetic + novelty×0.5) of the last winning iteration, as judged by the evolution model's own critic |
| final_aesthetic | Aesthetic component of final score (evolution model critic, 1–10 scale) |
| final_novelty | Novelty component of final score (evolution model critic, 0–10 scale; measures distance from parent) |
| cross_model_score | Aesthetic score from the cross-model judge (different model). NULL if cross-eval did not run for this run. Note: scale may differ from final_score — model calibration varies |
| cross_model_judge | Which model served as cross-model evaluator |
| best_baseline_a_xm | Highest cross-model aesthetic score among all from-scratch baseline attempts for this condition. NULL if no cross-model scores available for baselines |
| best_baseline_b_xm | Highest cross-model aesthetic score among all single-edit baseline attempts for this seed × taste × model. NULL if unavailable |
| score_vs_baseline_a | cross_model_score minus best_baseline_a_xm. Positive = evolution outperformed from-scratch generation on a common scale. NULL if either score missing |
| score_vs_baseline_b | cross_model_score minus best_baseline_b_xm. Positive = evolution outperformed single-edit baseline |
| final_distinct_commands | Number of distinct Logo command types in the final winner program |
| final_nesting_depth | Maximum bracket nesting depth (proxy for recursive/loop complexity) |
| final_code_length | Character count of the final winner program source code |
| final_spatial_entropy | Shannon entropy of the rendered final image (see Metrics Glossary). Higher = more complex image |
| final_fill_ratio | Fraction of canvas pixels that differ from background. Low = sparse, high = dense drawing |
| status | completed | error |
| elapsed_ms | Wall-clock time for this run in milliseconds |
| error | Error message if status=error, else empty |

### iterations.csv

| Column | Description |
| --- | --- |
| condition_id | Same as runs.csv |
| repeat_index | Which repeat |
| iteration | Iteration number (1-indexed) |
| winner_score | Total score (aesthetic + novelty×0.5) of the winning variant this iteration |
| winner_aesthetic | Aesthetic score of winner (1–10, evolution critic) |
| winner_novelty | Novelty score of winner (0–10, evolution critic; measures distance from this iteration's parent) |
| distinct_commands | Distinct Logo command types in the winner program |
| nesting_depth | Max bracket nesting depth of winner |
| color_changes | Number of SETPC/SETBG calls (colour change events) in winner |
| code_length | Character count of winner source |
| spatial_entropy | Image entropy of rendered winner (see Metrics Glossary) |
| fill_ratio | Fraction of non-background pixels in rendered winner |
| symmetry_score | Left-right luminance correlation (0=asymmetric, 1=perfectly symmetric) |
| num_variants_generated | Total variants the modifier produced (including invalid ones) |
| num_variants_valid | Variants that passed Logo syntax validation |
| model_used | Model that ran this iteration |
| modifier_latency_ms | API latency for the modifier call |
| critic_latency_ms | API latency for the critic call |

### baselines.csv

| Column | Description |
| --- | --- |
| condition_id | taste_id__model (no seed prefix — baselines are shared across seeds for type=from_scratch) |
| type | from_scratch (Baseline A) | single_edit (Baseline B) |
| model | Model that generated this baseline |
| taste | Full taste description text |
| seed_label | Seed used (Baseline B only; empty for from_scratch) |
| attempt_index | Which attempt (0-indexed, up to oneshotAttempts) |
| distinct_commands | Distinct Logo commands in this baseline program |
| nesting_depth | Max bracket nesting depth |
| code_length | Character count |
| spatial_entropy | Image entropy of rendered baseline |
| fill_ratio | Non-background pixel fraction |
| symmetry_score | Left-right symmetry (0–1) |
| bounding_box_coverage | Fraction of canvas area covered by the drawing's bounding box |
| latency_ms | API latency for the baseline generation call |
| xm_gemini_2_5_flash_preview_09_2025_aesthetic | Aesthetic score from cross-model judge gemini-2.5-flash-preview-09-2025 (1–10). NULL if cross-eval did not run |
| xm_gemini_2_5_flash_preview_09_2025_novelty | Novelty score from cross-model judge gemini-2.5-flash-preview-09-2025 (0–10) |

## Metrics Glossary

### Score Components

All scores from the evolution critic are on a 1–10 scale for aesthetic, 0–10 for novelty. The composite score is: **aesthetic × 1 + novelty × 2 + parsimony × 2**. Parsimony = max(0, 10 − commandCount/5). Note: these scores are **relative** — the critic sees the parent program as a reference, so scores can inflate over iterations as the baseline shifts upward. The cross-model scores are **absolute** — a different model evaluates the final program in isolation, providing a more stable scale.

### Structural Metrics (from Logo source)

| Metric | Description | High value means |
| --- | --- | --- |
| totalCommands | Total executable Logo commands | More complex, longer program |
| distinctCommands | Number of unique command types used | More varied drawing vocabulary |
| nestingDepth | Maximum depth of nested REPEAT brackets | More recursive/layered structure |
| colorChanges | Number of SETPC/SETBG calls | More colourful output |
| proceduresDefined | Number of TO...END procedure definitions | More modular/reusable structure |
| repeatCount | Number of REPEAT commands | More iterative/fractal structure |
| codeLength | Character count of source | Longer, potentially more complex program |
| tokenCount | Whitespace-delimited token count | More tokens, typically more operations |

### Image Metrics (from rendered canvas pixels)

| Metric | Range | Description | High value means |
| --- | --- | --- | --- |
| spatialEntropy | 0 – ~5.5 | Shannon entropy of a 16×16 luminance grid (H = −Σ p·log₂p). Computed by dividing the canvas into 16×16 cells, averaging luminance per cell, then computing entropy of that distribution. | More visually complex, space-filling image. Blank canvas ≈ 0; uniform noise ≈ 5.5 |
| fillRatio | 0 – 1 | Fraction of all pixels that differ from the background colour by more than a small threshold. | Denser, more covered drawing. A blank canvas = 0; fully covered = 1 |
| symmetryScore | 0 – 1 | Pearson-like correlation between left and right halves of the image using luminance values. | More left-right symmetric image. Many geometric Logo programs score high (0.8+) |
| edgeDensity | 0 – 1 | Fraction of pixels at colour boundaries (neighbouring pixels differ by > 30 in any channel). | More detailed, fine-grained drawing |
| distinctPixelColors | 1 – ~millions | Number of unique quantised colours in the rendered image. | More colourful, varied output |

### Render Metrics (from Logo drawing queue)

| Metric | Description |
| --- | --- |
| totalPathLength | Sum of Euclidean lengths of all line segments drawn (pixels). Proxy for how much the turtle moved |
| operationCount | Total draw operations (lines + dots) in the render queue |
| distinctColors | Unique colours used in actual drawing operations |
| boundingBoxCoverage | Fraction of 400×400 canvas area covered by the drawing's axis-aligned bounding box |
| lineCount | Number of line segments drawn |
| arcCount | Number of arc/dot operations drawn |

## Summary Statistics
- **Conditions:** 4 (2 seeds × 1 tastes × 1 models)
- **Evolutionary runs completed:** 12 (0 errored, 12 Baseline C)
- **Baseline A (from-scratch) attempts:** 10
- **Baseline B (single-edit) attempts:** 40


**Score vs Baseline A (from-scratch), cross-model judge:**
- Comparable pairs (both sides have cross-model scores): **10**
- Evolution beat best baseline A: **0/10** (0%)
- Mean score_vs_baseline_a: **-1.800** (positive = evolution wins)
- Std dev: **0.632**


**Score vs Baseline B (single-edit), cross-model judge:**
- Comparable pairs: **10**
- Evolution beat best baseline B: **0/10** (0%)
- Mean score_vs_baseline_b: **-2.400**
- Std dev: **1.897**


**API Call Statistics:**
- Total API calls logged: **634**
- Catastrophic score drops detected (>4 point drops): **51** — filter iterations.csv on `score_drop_warning=1` to inspect


**Self-score vs cross-model score gap:** Evolution critic avg = **31.82**, cross-model judge avg = **1.20**, gap = **30.63 points**. This gap is expected: the evolution critic uses relative scoring (comparing against the parent), inflating scores over iterations. The cross-model judge evaluates the final program in isolation against an absolute standard.

## Suggested Analysis Questions

*The following questions are designed to guide an LLM analyst working with the attached CSV files:*
- 1. **Does evolution consistently outperform one-shot generation (Baselines A and B)?** Analyse final scores against baseline distributions for the same condition.
- 2. **Does the critic feedback loop alone (Baseline C) account for the improvement, or does selection pressure (multiple variants) add value beyond feedback?** Compare evolution vs Baseline C trajectories and final scores.
- 3. **Do different models show different evolutionary dynamics?** Compare score trajectories grouped by model.
- 4. **Do the structural metrics (code complexity, nesting depth) increase over iterations?** Is structural complexity correlated with aesthetic score?
- 5. **Do models agree when cross-evaluating each other's outputs?** Analyse the cross-model scores for evidence of model-specific aesthetic bias.
- 6. **Is there a tradeoff between aesthetic score and novelty score during evolution?** Does one tend to increase at the expense of the other?
- 7. **How much variance is there across repeats of the same condition?** Is the evolutionary outcome reliable or highly stochastic?
- 8. **Does evolution tend toward shorter or longer programs?** How does program length (command count) relate to visual quality (spatial entropy, fill ratio)? Do one-shot baselines produce different length profiles than evolved programs?
- 9. **How often do catastrophic score drops occur** (winner score drops >4 points between consecutive iterations)? Check `score_drop_warning` in iterations.csv. Are these associated with specific conditions or iteration depths?
- 10. **Based on the patterns in this data, what follow-up experiments would be most informative?** Consider: different fitness weightings (pure aesthetic, pure novelty, parsimony pressure), prompt interventions (nesting encouragement), increased repeats, deterministic vs probabilistic selection, and multi-model comparisons.

## How to Use This Brief

Upload this file alongside the CSV files to your LLM of choice. Suggested prompt: *"I have run a Logo turtle graphics evolution experiment. The attached analysis_brief.md explains the research question, experimental design, column meanings, and summary statistics. The attached CSV files contain the data. Please answer the analysis questions at the end of the brief, and highlight any unexpected patterns. Pay particular attention to: (1) the score_drop_warning column for catastrophic evaluation failures; (2) nesting_depth across iterations to see whether structural complexity increased; (3) the run_type column to distinguish evolution from feedback-only baseline runs."*