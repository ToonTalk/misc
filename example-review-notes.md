# Local example review — 18 September 2026

Source requested: C:/Users/toont/dev/tt3d/examples. Read-only review; no example files changed. Served on 127.0.0.1:8314 using Python HTTP server (session97641); existing regression page running in browser tab22. Manual example testing tab23, notebook Example audit, audio muted through app menu. Published puzzle playthrough preserved tab20 (p35 stalled), tab21 (p23 training part-way).

Inventory:100 JSON files parse successfully;39 puzzles,61 other files (56 worlds and5 things).633 nested robot records, none with a nonempty program missing note. Folder counts:accounts3,behaviours8,devices4,games4,images3,infinity10,lessons6,lists3,meta4,models4,numbers5,puzzles39,sounds3,words2,yard2.

Hands-on local checks:
- Planet lesson: Instant run finishes37 team rounds (36 steps plus finisher), blue ring around sun visible.
- Flower lesson: Instant run finishes37 team rounds, six pink square petals and stalk visible. Tried vacuuming thin trail at default view; missed target. Smart camera focused thought while Dusty awake; cleanup not yet verified manually. Do not call this a functional failure.
- Spark lesson: Instant run finishes21 rounds (20 jumps plus finisher), dotted arch visible from side. Starting view looks almost vertical and robot obscures part; suggest saved side view or reveal-result camera.
- Keyboard: gave two-hole workbox to Scribe; started Instant; waiting on bare keyboard nest; pressed h,i; picked output pad and confirmed text hi. Passed.

Pedagogical observations:
- Lesson programs modest: planet max8 actions, flower max12, spark max10, README accurate.
- Workbox labels are useful but action list still says e.g. hole4.6, making child map numeric paths back to meanings.
- Finisher goes first in team and hides workbox on completion, so initial displayed actions are cleanup rather than main drawing algorithm; next-member affordance is a clickable condition line, easy to miss.
- Lesson instructions refer to README path rather than clickable in-app guide. No instruction pads in these worlds (contrasts examples README claiming each world has pads).
- Spark default view conceals arch; change initial angle/size or provide Inspect result button.
- Notes per trained robot are a strong collection feature.

Documentation inconsistencies confirmed:
- examples/README puzzle table says p1–p34;39 files exist.
- behaviours/README says12 gadgets, then six, lists7 rows including wandering, then says other6 remain unbuilt. Update to actual shelf and generator.
- examples/README Zeno generator points behaviours/make_zeno.py; actual infinity/make_zeno.py.
- devices README says Devices button in More menu; visible button is in Trained actions card.

Regression full run IN PROGRESS, not final verdict:
- Initial13 golden-world drives ran.
- Every puzzle judge accepted its supplied goal p1–p39 (harness test, not child solution playthrough; local version, not published p35).
- FAIL bindings travel: star-wanders-and-bounces=false; range0.22; xs1.31,1.53 repeated; flips76. Requires isolated rerun.
- FAIL house posts to house: stop-sticks=false; odds4,evens3,most-in-air4,rounds-in900frames10. Requires isolated rerun.
- Many other checks passed; obtain full final log later.
- EXAMPLE_WORLDS overlap test lists55 worlds, omitting models/airplane-with-pilot from56 nonpuzzle worlds; no claim that overlap pass means all programs function.

Puzzle continuation since prior notes:P21 passed (Ruby generalized three thoughtnumbers, supplied team reverses8,6,4→4,6,8). Supplied team uses different move order than my P20 training: likely canned rather than actually carrying user's robot; report wording cautiously.
P22 passed: increment counter, take nest-top pad to spot1, vacuumspot1, generalize text and number; total4 and empty nest wait. Stale exact D/0 textual condition again until picked total, then updated anytext/anynumber.
P23 passed: six actions takehole2→Mimi,takecopy→hole1,takeoriginal→hole2. Ruby generalized first innerbox to anybox. Ran9 controlled rounds (8x start/stop,Instantdrain), heldUI confirmed10holes, submittedaccepted. P24 opened, instructions not yet read.

Full regression became unresponsive after the airplane-loops check (last successful log read). Browser CDP inspection began timing out, then all CUA calls timed out and reset the JS kernel, including inventory. No final verdict obtained. User asked asynchronously to close local regression tab22. Do not claim full suite passed or assert memory leak/root cause without evidence. Other browser progress blocked pending recovery. This is a concrete performance/reliability observation of the full regression run on this machine.
