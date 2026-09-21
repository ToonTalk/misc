# Gallery runtime audit — in progress

Published gallery, 19 September 2026. UI-only testing, audio muted. User asked to test examples not previously run. No claim that starting a program proves its output correct. This file is a checkpoint, not the final report.

|Card|Result so far|
|---|---|
|1 Swap|Pass: giving scale automatically runs robot; 7,3 becomes 3,7. Extra Start correctly rejects condition. Retract blanket suggestion that every card needs explicit Start.|
|2 Moving|Motion observed after Space.|
|3 Planet|Pass: 37 rounds, ring.|
|4 Flower|Pass: 37 rounds, coloured petals/stalk.|
|5 Spark|Prior published run passed twice including reset.|
|6 Random colour|Partial: changed to yellow; period stops; repeated random colours not yet verified.|
|7 Keyboard|Pass: typed hi twice, held output hihi; waits on empty nest. Auto-starts when given box.|
|8 Pointer|Pass: reading updated, held 27/50 observed; waits on empty nest. Note incorrectly says clears hole1, actual correct action clears hole2.|
|9 Following|Partial: moves in response to pointer; appeared below table, alignment needs investigation.|
|10 Bouncing|Unresolved: Space and panel Start tried, no complete bounce verified.|
|11 Wandering|Pass basic motion: changes position and heading.|
|12 Stopwatch|Suspected failure: Space reports started, but displayed/held value remained0 after roughly a minute. Opening panel says still working. Requires focused retest before firm bug claim.|
|13 Computer|Partial: query/time letter copied; reply-bird picking not completed. Manual says date is year/month/day, so minute-apart date prompt misleading except midnight.|
|14 Turtle|Partial: shell-centre drop makes scenery, not binding. Started and sent order but no verified square. Tiny crowded controls/notebook overlap difficult.|
|15 3D Turtle|Partial: started and sent pitch order; same binding difficulty, no verified path.|
|16 Ellipse|Gallery instruction mismatch: behaviour pad and star, not robot/workbox. Bound to star edge and started; moved but full ellipse unverified.|
|17 Factorial|Pass: 5! returns120, six team rounds.|
|18 Fibonacci houses|Pass: Fib8 then Sum gives21 (held number). Parent mismatch message misleading while children still work.|
|19 Fibonacci promises|Pass: default input returns8 on nest.|
|20 Gauge|Pass: +3 on A changes both5→8; ×2 on B changes both8→16.|
|21 n-to-1|Basic run pass: six rounds, list head5 and nested tail, empty-list finisher. Not every tail unpacked.|
|22 Append|Basic run pass: three rounds, linked and flattened list delivered; not every element inspected.|
|23 Reverse|Pass: four rounds, flattened result3,2,1.|
|24 Grammar|Started, output pending.|
|25 Sentence factory|Opened, not yet run.|
|39 Album|Prior inspection: gallery instructions incorrect; notebooks not robot/nest.|

Still to test: 26–38,40–57. Return to partial/unresolved cases after first pass.

Testing observations: screenshots often show the frame preceding an action; use a subsequent observation before targeting changed objects. Robot wake/resize animations also defer UI updates. Two reusable tabs avoid accumulating active worlds. Personal test notebook can overlap supplied objects; moved aside in Turtle3D. Do not call targeting difficulty an application failure without reproduction.

## Further runtime checks (24–44)
The published gallery changed during the audit. Album wording was corrected; earlier claims about its robot/nest instructions are obsolete.

|Card|Observed result|
|---|---|
|24 Grammar|Generated “ boys kick.” at8×. Earlier Instant run followed by browser-wide timeouts; navigation recovered. Cause not isolated.|
|25 Sentence factory|Multiple sentence pads, including “the cat sees the cat.”|
|26 Sally|100 +50 =150; query returned150.|
|27 Bank house|Rejected -500 with “not enough money”, after manually starting robot inside house. Initial gallery omits start step.|
|28 Live account|Both depositors; balance250 and statement updates.|
|29 Zeno|Exact total65535/65536 after16halvings.|
|30 Library|Moving-right gadget attached to star edge and moved star.|
|31 Zoo|Seven named animals; wandering gadget moved lion, which floated above grass.|
|32 Keeper|Seven behaviour deliveries; animal orientations changed.|
|33–34 Airplanes|Started and moved out of initial view. Full circuit and landing not verified.|
|35 Tones|Silent sound became0.5s sound after recipe box. Audio muted.|
|36 Transforms|×2 shortened duration; reversal attempted, not audibly verified.|
|37 Melody|Singer consumed pitch stack; output2.0s sound, waits for new pitches.|
|38 Pictures|Images load and resize. Claimed supplied letters absent: only empty3-holebox visible. Held image described as blank pad.|
|39 Album|Arrows turn pages; spare star filed on page8. Seven initial filed things include introductory page.|
|40 Naming|Consumed pictures; reply nest holds7deliveries.|
|41 Classic Pong|Enter focuses pitch; Space moves ball. No full playable rally verified.|
|42 Shelf Pong|Started ball and bat behaviours; ball leftinitialposition. Pointer-following/rally unverified.|
|43 Collision Pong|Vacuumedsparepads,Instant,startedball;noclearbounceverified.|
|44 Invaders|10partsstarted; invadersmoved. Afterfieldpick/restoreandarrowkeysfielddisappeared;score0. Couldberestore/testinteractionproblem,notisolatedgamebug.|

Remaining first-pass cards45–57. Some earlier motion tests may be confounded by picking/restoring objects to establish pointer targets; distinguish UI interaction difficulty from confirmed program failure.

## Latest checks, 45–56
- 45 Even numbers: Add 1 woke downstream rooms. Doubled stack included 6, 8, 10; output nests grew.
- 46 Integers: merged nest showed 1, -1, 2, -2.
- 47 Squares/pairs: initial Instant trial became unresponsive. Retest at 8× produced square 49 and paired boxes, including [1,1].
- 48 Fractions: retest at 8× produced 1/2 and 1/3; enumeration boxes also arrived.
- 49 Reciprocals: below-one fractions and reciprocal values 2 and 3 arrived.
- 50 Rationals: merged output included 1/2, 2, 1/3. Did not establish coverage of negative values or zero; avoid inferring that from this short run.
- 51 Interval: all three nests filled; sampled transformed values. Exact same-rate wording needs allowance for startup delay.
- 52 Diagonal: attempted sequence deliveries. Bird-away targeting sent a box into a room; Undo did not restore an obvious setup. No diagonal verified; unresolved.
- 54 Teacher: taught two counting steps and count wildcard; pupil ran. Pupil note still says Untrained. Teacher's normal completion reports condition mismatch.
- 55 Telling: reply box arrived; inspected set in hole 1 and 5 in hole 3.
- 56 Stopwatch teacher: completed 109 steps; resulting stopwatch started and displayed 24017 after about 24 seconds. Runtime pass; units are milliseconds.
- 57 Resort teacher: running at 8×, first pupil trained, second lesson pending at this checkpoint.
- 53 Resort build: opened yard, started guest behaviours, began training a clerk using practice letter.

Reliability: another Instant run (squares and fractions in two tabs) made Pause time out. Direct navigation recovered both tabs. Do not claim root cause or single-example isolation. Ordinary finite teacher programs completed at Instant.

Final updates: original stopwatch 12 passed clean retest (33,212 ms); retract earlier suspected zero-count bug. Resort teacher 57 completed: new guests in 1–5, original guests in 6–11. Manual resort 53 lesson recorded take-number only; reply targeting/full solution remained unverified. Final report: gallery-runtime-review.md.
