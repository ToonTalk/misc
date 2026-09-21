# Published ToonTalk 3D gallery: runtime test report

Tested 19 September 2026 using the published gallery and workshop UI. Audio remained muted. This extends the earlier review, which did not execute every example.

## What this report establishes

Every one of the 57 cards has an explicit coverage entry below. **This is not a claim that all 57 passed, or that every build activity was completed.** Results distinguish observed outputs, basic motion/start checks, and unresolved tests. Optional challenges were sampled, not exhaustively tested. Infinite enumerations were sampled; a finite run cannot prove completeness.

The published gallery changed during the audit. In particular, the album instructions were corrected. Earlier criticism of its robot/nest instructions no longer applies. Giving a box to a trained robot often starts it automatically; my earlier general suggestion that every card needs a separate Start instruction was too broad.

## Findings to address first

1. **Instant mode can make infinite examples unresponsive.** A Grammar run, and later a session running the squares/fractions pipelines at Instant, were followed by browser-control timeouts. Pause could not be activated; direct navigation recovered the tabs. The pipelines worked at 8×. This is an observed reliability problem in this test environment, not an isolated root-cause diagnosis. Bound each execution slice and let Pause/reset interrupt it. Finite examples, including the 109-step stopwatch teacher, completed at Instant.

2. **Some Run instructions do not match the supplied world.** Ellipse asks for a robot/workbox, but supplies a behaviour and star. Pictures asks for supplied letters, but I found six pictures and an empty three-hole box, without ready-made letters. Bank account in a house did not process my request until I started the robot inside; add the house-switch step. For each card, name the exact target, show the first action, and state the expected visible result.

3. **Successful teaching looks like failure.** Teachers finish with a condition-mismatch message advising changes to the thought. This is normal for these one-shot teachers. The taught pupil also retains an “Untrained” note. Show successful completion separately from unexpected mismatches, and distinguish a saved descriptive note from current training status.

4. **Object targeting is a substantial learning obstacle.** A behaviour dropped on a pad's centre becomes scenery; the edge binds it. Tiny house switches can instead pick up a house. A bird may be away when the next letter is dropped, causing the letter to land in the room behind it. The personal notebook overlapped some supplied objects. The drop hints help, but larger targets, a clearly marked binding target, a stable mailbox target, and a way to move the notebook aside would improve these examples.

5. **Camera and information panels can hide the activity.** At a narrow viewport the title panel obscured the back door. Outdoor scenes required zooming out to see all the actors. Several moving examples left the initial view. Provide an activity-specific initial camera, a reliable “fit this example” action, and collapsible panels that do not obscure essential controls.

6. **State the mathematical and measurement conventions.** The stopwatch counts milliseconds; label that. The computer example's date query gives year/month/day, so comparing dates a minute apart normally shows no change. Say that a pipeline's outputs correspond term by term while allowing transit/startup delays, rather than promising visibly identical counts at every instant. The short rational-number sample does not establish inclusion of zero or negatives; the title should explicitly match the intended set.

7. **Picture accessibility descriptions omit the picture.** Held pictures were described as “a blank pad”; picture-matching robot thoughts appeared as empty text. Include the image's accessible name/description in these summaries.

## Coverage and actual observations

“Observed” means the stated result was seen. “Basic” means an action or motion worked but the complete advertised behaviour was not established. “Unresolved” is not a confirmed program bug.

| # | Example | Result and evidence |
|---|---|---|
| 1 | Swap | Observed: 7,3 became 3,7 when given to the robot. Extra Start correctly rejected the now-changed condition. |
| 2 | Moving | Basic: motion after Space; complete path not checked. |
| 3 | Planet | Observed: 37 rounds and ring output. |
| 4 | Flower | Observed: 37 rounds and coloured petals/stalk. |
| 5 | Spark | Observed in the preceding published test: 21 rounds, repeated after reset. |
| 6 | Random colour | Basic: colour changed to yellow and period stopped it. Repeated distinct random colours not established. |
| 7 | Keyboard | Observed: typing hi twice produced hihi; waits on an empty nest. |
| 8 | Pointer | Observed: reading updated; held value 27/50. Robot note names the wrong cleared hole (1 instead of 2). |
| 9 | Following the pointer | Unresolved: movement occurred, but alignment with the pointer was not established. Picking/restoring the target may have affected the test. |
| 10 | Bouncing | Unresolved: started through Space and panel; a complete edge bounce was not established. |
| 11 | Wandering | Basic: position and heading changed. |
| 12 | Stopwatch | Observed on clean retest: displayed 33,212 after about 33 seconds. Earlier suspected zero-count failure is retracted. |
| 13 | Computer | Incomplete: prepared a query but did not complete reliable reply-bird targeting. Date/minute prompt issue noted above. |
| 14 | Turtle | Unresolved: started and sent an order, but no square verified. Centre-versus-edge binding and crowded objects caused difficulty. |
| 15 | Turtle in the air | Unresolved: started and sent a pitch order; complete path not verified. Same binding difficulty. |
| 16 | Ellipse | Instruction mismatch. Bound behaviour to star edge and started it; motion observed, full ellipse not established. |
| 17 | Factorial | Observed: 5! = 120, six team rounds. |
| 18 | Fibonacci houses | Observed: Fib 8 then Sum produced 21. Parent mismatch message appeared while child work was still relevant. |
| 19 | Fibonacci promises | Observed: default Fib 6 returned 8 on the nest. |
| 20 | Gauge | Observed: +3 changed both 5 to 8; multiplying the other by 2 changed both to 16. |
| 21 | n-to-1 | Basic output: six rounds, head 5 and nested tail; every tail was not unpacked. |
| 22 | Append | Basic output: three rounds; linked and flattened output delivered. Not every element inspected. |
| 23 | Reverse | Observed: four rounds; flattened result 3,2,1. |
| 24 | Grammar | Observed at 8×: sentence “ boys kick.” Instant reliability issue described above. |
| 25 | Sentence factory | Observed: multiple sentence pads, including “the cat sees the cat.” |
| 26 | Sally's account | Observed: deposit 50 changed 100 to 150; query returned 150. |
| 27 | Bank account in a house | Observed: -500 request returned “not enough money” after manually starting the house's robot. Initial start instruction missing. |
| 28 | Live account | Observed: two depositors produced final balance 250 and statement updates. |
| 29 | Zeno's postman | Observed: exact running total 65535/65536 after sixteen halvings. |
| 30 | Shelf of behaviours | Basic: moving-right gadget bound to star edge; star moved. Did not test all sixteen gadgets or the combined challenge. |
| 31 | Zoo | Observed seven named animals. Wandering bound to lion and moved it; it appeared above the grass. |
| 32 | Zoo keeper | Observed seven behaviour deliveries and changed animal orientations. |
| 33 | Airplane flight | Basic: started and moved out of initial view. Full loop and advertised landing not verified. |
| 34 | Airplane with pilot | Basic: started and moved. Pilot remaining aboard throughout the entire flight not verified. |
| 35 | Tones | Observed: recipe box made a silent sound into a 0.5-second sound. Audio not heard. |
| 36 | Sound transforms | Observed shortening after multiplication; reversal attempted. Pitch/reversal not audibly verified because muted. |
| 37 | Melody | Observed: Singer consumed pitches and produced a 2.0-second sound, then waited on the empty nest. Audio not heard. |
| 38 | Pictures | Pictures loaded and resized. Supplied-letter Run instruction could not be followed: only an empty three-hole box was visible. |
| 39 | Album | Observed page turns and spare star filed on blank page 8. Seven initially filed things include an introductory page. |
| 40 | Naming pictures | Observed: input consumed; reply nest held seven deliveries. |
| 41 | Pong from parts | Basic: Enter close-up worked and ball moved. Full rally/pointer control not verified. Clicking to reposition the pointer also picks up the scene, limiting this test. |
| 42 | Pong from shelf | Basic: ball's three behaviours and bat's following behaviour started. Full playable rally not established. |
| 43 | Pong with collisions | Unresolved: spare pads vacuumed, Instant selected, ball started; no clear bounce verified. |
| 44 | Space Invaders | Basic: ten parts started and invaders moved. Hits/scoring not verified. Field disappeared after pick/restore and arrow interaction; cause not isolated. |
| 45 | Even numbers | Observed: downstream rooms woke; doubled stack included 6,8,10 and output nests grew. |
| 46 | All integers | Observed merged sample 1,-1,2,-2. |
| 47 | Sequences and pairs | Observed on 8× retest: squares including 49, and paired boxes including [1,1]. Initial Instant test became unresponsive. |
| 48 | Fractions between 0 and 1 | Observed on 8× retest: 1/2 and 1/3 plus enumeration boxes. Infinite completeness not proved. |
| 49 | Fractions above one | Observed below-one fractions and reciprocal outputs 2 and 3. |
| 50 | All rationals | Observed merged sample 1/2,2,1/3. Did not establish negative/zero coverage or full enumeration. |
| 51 | Any interval | Observed all three nests filling with transformed values. Did not prove exact timing or all correspondences. |
| 52 | Counting sequences | Incomplete: attempted sequence deliveries; a delivery while the bird was away landed in a room. Diagonal output not established. |
| 53 | Resort Infinity | Build activity inspected and guest behaviours started. Clerk training begun on the practice letter; the take-number step was recorded, but reliable targeting of the reply bird was not completed. Full manually built solution not verified. The automated solution in card 57 passed. |
| 54 | Teacher | Observed two counting steps and wildcard taught; pupil started repeating. Completion message and stale Untrained note are misleading. |
| 55 | Telling | Observed reply box; inspected set in hole 1 and 5 in hole 3. |
| 56 | Stopwatch teacher | Observed completion of 109 steps and functioning constructed stopwatch, displaying 24017 after about 24 seconds. |
| 57 | Resort teacher | Observed full demonstration: teacher taught and dispatched both robots; five new guests occupied cottages 1-5, and six original guests moved to cottages 6-11. Teacher finished normally with the misleading condition-mismatch message. |

## Recommended gallery improvements

- Add a small annotated first-action picture and expected-result picture for every Run instruction.
- Include an explicit stop/reset step for unbounded examples and recommend a safe speed.
- Separate “run the supplied program” from “build the missing program”; give build activities a direct link to the precise lesson and a finished-world comparison.
- For games, include an unmistakable Play mode that disables accidental pickup and shows controls.
- Provide a visible progress indicator and expected completion state for teachers and multi-house pipelines.
- Make manual/automated test reports say exactly which outputs were verified; loading or starting is not a full pass.

