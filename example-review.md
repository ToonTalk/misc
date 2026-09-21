# ToonTalk 3D example review

18 September 2026 · Local files in `C:\Users\toont\dev\tt3d\examples`

**The three revised drawing lessons work, and their small teams and labelled boxes are a useful teaching improvement. The wider collection is promising, but this is a partial runtime review: the full regression runner became unresponsive before its final verdict.** No source example files were changed. Audio was muted in the local app as requested.

## What was tested

| Check | Result |
|---|---|
| Parse every example JSON | 100/100 valid: 39 puzzle files and 61 other files |
| Check number records for zero denominators | None found |
| Check trained robots for explanatory notes | No missing notes among nonempty programs; 633 nested robot records, including embedded copies/templates |
| Run revised planet lesson through app UI | Pass: visible ring, 36 working rounds plus finisher |
| Run revised flower lesson through app UI | Pass: six square petals and stalk, 37 total team rounds |
| Run revised spark lesson through app UI | Pass: dotted arch, 20 jumps plus finisher |
| Operate keyboard example through app UI | Pass: supplied box to Scribe, Run, press h and i, output pad reads `hi` |
| Existing full regression page | Incomplete; two failure lines observed before browser control stopped responding |

The accompanying `example-coverage.csv` lists every file and separates static checks from manual local execution. Parsing and explanatory notes do **not** establish correct program behaviour. Sound examples were not assessed by listening because audio was requested muted.

The regression runner reported that all 39 local puzzle judges accept their supplied goal. That checks the judge fixtures; it does not establish that a child can construct every answer. It also does not invalidate the separate failure observed in the published current-year puzzle.

## Problems requiring investigation

### Combined wandering and bouncing: regression failure

The existing `bindings travel` check reported `star-wanders-and-bounces=false`. Recorded across positions were approximately 1.31, then 1.53 repeatedly, despite 76 direction flips. Binding, persistence and Ruby release checks passed in that same test.

This suggests a boundary interaction worth isolating, rather than a general failure to attach behaviours. Reproduce with the repository's documented `tests/regress.html?checks=bindingsCheck` filter. An isolated rerun was not completed, so this remains a test failure requiring confirmation.

### House-to-house program: Stop check failed

The existing `a house posts to a house` check reported `stop-sticks=false`; delivery and motion counters were nonzero. Reproduce with `tests/regress.html?checks=postAcrossCheck`. Check whether stopping the sending house prevents new work while allowing already-sent letters to finish. Do not infer a specific engine cause from this one result.

### Full regression run became unresponsive

The last successfully read output included a passing airplane-loop check. Subsequent inspection timed out, followed by failures to inspect the other browser sessions. Closing the regression tab succeeded, but browser control did not recover during this review. There was no final suite verdict.

Split the suite into bounded groups or fresh app instances, write progress after each check, and identify the check currently running. The observed behaviour does not by itself prove a memory leak or establish which check caused it.

## Comments on the revised lessons

**Planet:** the clearest starting lesson. Its main robot has eight actions and a four-hole work box. Predicting nine steps versus eighteen provides a concrete link between turn size and a complete circuit. Explain that the displayed 37 rounds are 36 steps plus cleanup, not 37 drawing steps.

**Flower:** the four jobs make the nested repetition understandable. The largest robot has twelve actions, consistent with the guide. Invisible connecting strokes are a useful way to retain separated petals while making one trail. I verified the drawing, but did not successfully complete a manual vacuum/save/reimport check of the whole flower; thin targets and camera movement made that check awkward. That is an unverified interaction, not a confirmed failure of the change.

The `sides left` counter starts at five although the petal is a square. The guide explains that the outward journey consumes one count, but the label still invites confusion. Call it `petal steps left`, or give the outward journey its own state and reserve `sides left` for four actual sides.

**Spark:** changing the number inside the upward-step letter is a good next concept after fixed movement. The default view makes the dots look nearly vertical and partly hides them behind the robot. Rotating to a side view reveals the arch. Save a better initial angle, enlarge the dots, or provide a “look at the result” action.

**Across all three:**

- Use box labels in the action list: `copy letters → pink ink` is easier to follow than `copy hole 4.6`.
- Provide a visible team-member selector. Clicking the condition sentence to cycle members is easy to overlook.
- Explain why the finisher is first, but initially show the main working robot when teaching the recipe.
- Put the experiments inside the world, or offer a direct guide link. Marty currently refers to a filesystem README path.
- Keep a visible restart invitation after completion. Putting the work box away is a clear stopping mechanism, but also removes the data a learner might want to inspect or change.
- Demonstrate helper-card attachment explicitly. The three standalone helper cards were not manually verified in this review.

## Collection-level teaching suggestions

These are judgments from the documentation and program structure, not claims of full runtime verification.

| Group | Teaching value and suggested next step |
|---|---|
| Numbers and basic behaviours | Start with swap, moving, and the planet: one visible change, a small robot, and a predictable result. State valid input ranges before inviting changes. |
| Devices | Keyboard is an especially clear example of a robot waiting for a message. Add a before/after card showing one key becoming one delivered pad. |
| Lists | Showing both the lazy list and flat-box conversion is valuable. Colour corresponding links and explain why a nest can stand for an answer that has not arrived yet. |
| Accounts | Make a short sequence of requests with predicted balances, including exactly-empty and insufficient-balance cases. Contrast the open account with the house enclosing its state. |
| Words | Present the four-robot grammar interpreter after the fixed sentence factory, with a tiny editable dictionary. Editing data without retraining is the central lesson. |
| Games | Separate “play it,” “inspect one behaviour,” and “build a small part.” The full game is a motivating destination, but too much to explain at once. |
| Infinity | Give each activity one finite trace to inspect before discussing its unbounded continuation. Keep the distinction between any finite stage and the infinite mathematical object explicit. |
| Meta examples | Reserve for later. First show the pupil's desired program, then watch its teacher construct it; keep both programs inspectable side by side. |
| Models, images, sounds and yard | Pair each visible object with one small behaviour and a single experiment. Provide textual sound expectations so the examples remain usable when muted. |

Add a gallery with prerequisites, approximate complexity, a screenshot, Run, Reset, and one “change this and predict” prompt. The current folder organisation is useful for authors; a learner needs an ordered route through it.

## Documentation fixes

- The main examples table says puzzles `p1`–`p34`; there are 39 files.
- The behaviours guide says twelve gadgets, then six, lists seven rows, and later says the other six remain to be built. Reconcile the count and build instructions with the actual library.
- The Zeno section points to `behaviours/make_zeno.py`; the file is in `infinity`.
- The devices guide places the Devices button in the More menu; in the tested app it is in the Trained actions card.
- The main guide says every world includes instruction pads; the three lessons use Marty introductions instead. Describe both approaches.
- The overlap-test list contains 55 non-puzzle worlds; the collection contains 56. `models/✈️ airplane-with-pilot.world.json` is absent from that list. An overlap check also needs to be distinguished from functional execution coverage.

## Remaining work

Isolate the two regression failures; finish the automated run in smaller groups; test the remaining examples interactively, including input boundaries, helper attachment, saving/reloading and sound behaviour without audible playback. The earlier published puzzle playthrough has completed 1–23; puzzle 35 stalled, and 24–34 remain. The local collection additionally contains 36–39. These gaps are deliberately left visible rather than reported as passes.
