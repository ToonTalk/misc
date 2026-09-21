# ToonTalk puzzle playthrough — in progress

Started 18 September 2026 through the app's Puzzle game entry, using a separate `Puzzle audit` notebook identity. User asked to use the app; testing proceeds through its UI. No app internals or programmatic completion calls are used.

| Puzzle | Objective | Actual test | Result |
|---|---|---|---|
| 1 | Make box [1,2] and give to bird | Picked up supplied 1 and 2, placed in two-hole box, delivered box to bird | Next puzzle enabled; transition to puzzle 2 successful |
| 2 | Make 4 | Dropped one supplied 2 onto the other; held UI confirmed 4; gave to bird | Next puzzle enabled |
| 3 | Box [8,16,32] | Asked hint, added spare 16 to final 16, joined three boxes at edges | Accepted; advanced to 4 |
| 4 | Zero | First submitted 3; read rejection pad; added −3 to returned 3; submitted zero | Wrong answer rejected and returned; correct retry accepted |

P5 passed: used hint, trained robot to put its one-hole [0] box on Mimi, take copy to desk, retrieve original and join; ran once and submitted accepted result. An accidental pickup of the number instead of the whole box was successfully undone, including removal of its recorded step. Correct completion got generic red mismatch prompt suggesting Ruby/Dusty, despite correct result being ready.

P6 passed: trained take nest-top / add to total, used Ruby on both thought numbers, ran to 9 and waited on empty nest; submitted 9 and advanced. Reproducible stale condition text: thought cubes changed to ?, but text still said 4 and 0 through run and waiting; picking up resulting 9 refreshed it to any number/any number.

At 692px wide, Mimi was off-screen until two zoom-out scrolls; then whole boxes and numbers have very small distinct targets. IMPORTANT qualification: later opened menu and found Smart camera OFF, inherited from previous session. Do not describe missing camera help as a default-camera bug. A 1280x800 viewport comparison request did not visibly alter screenshot dimensions; reset before finish. Manual's Puzzles section describes 35 puzzles total (first seven plus twenty-eight).

P7 in progress: all four hints tested, trained six-step copying/addition robot and generalized thought. Running at 8×. Intro says 'Last of all' despite 28 further puzzles; likely stale story progression. Final hint correctly explains Stop finishes current round, says press at 512, and warns overshoot requires restart.

User requested mute; used More → sound button and reopened menu to verify 🔇 (sound and voices included). Preserve mute.

P7 passed: trained copying/addition, Ruby to any number. Stopped first run after 1 round, Instant second run after 6 rounds. Then used 8× Start/Stop followed by Instant to finish each stopped round. Verified 512 in hand, put back with ↩, ran/stopped one further round, verified 1024 and submitted; accepted. This is valid UI execution, but not a clean test of watching 512 appear during a continuously animated run. Recommend single-round stepping and non-destructive overshoot recovery.

P8 passed: nested three supplied two-hole boxes in first holes, delivered outside box.
P9 passed: copied zero twice, filled three-hole box, placed it in SECOND hole of outer box, delivered; accepted.
P10 passed: copied pair of zeros twice, joined all three pairs, submitted six-hole box; accepted. Tooltip says '6 holes, holding 0, 0, 0, 0' without ellipsis (truncation can mislead).
P11 passed: combined 64+8+4+1 into 77 and submitted. Next puzzle unexpectedly numbered 35 (likely inserted exercise, but confusing numbering).
P35 blocked: objective current year. Combined 1024+512+256+128+64+32+8+2 into 2026, confirmed in held UI, delivered. No acceptance, rejection or Next after repeated checks for over a minute. Entered judge; manual Start led to WAITING ON A NEST (hole1). Console warnings/errors empty. Inspected visible robot steps, including date request and subtract-year checking; root cause unconfirmed. Preserved tab20. Opened p12 through normal app world URL (grounded in judge's open-world p12 step) to continue testing.

P12 passed: divide1 by2, confirmed1/2, accepted.
P13 passed: copied times10 operator with Mimi five times, applied to10, confirmed1000000, accepted.
P14 passed: typed A,B,C onto supplied blank pads, placed in corresponding three-hole box, accepted.
P15 passed: multiplied365 by24,60,60; confirmed31536000, accepted.
P16 passed: joined Talk at right edge of Toon, confirmed ToonTalk, accepted.
P17 passed: divided1 by4 then multiplied3, confirmed3/4, accepted.
P18 passed: put3/4 on left scale pan and2/3 onright; delivered scale, accepted.
P19 passed: copied/joined3-zero box by successive doubling to6,12,24; heldUI confirmed24holes, accepted. Large boxes compress middleholes; explicit contents/count summary helpful. Tooltip continues truncating contents without ellipsis.
P20 passed: tried taking stucknumber byhand, received clear robot-claw feedback. Trained six-step transfer nestedbox1 hole3→box2hole1,2→2,1→3; exited and ran once. Delivered full outerbox, accepted. Again red condition-mismatch message after intended single run risks sounding like failure.

Early observations: successful answer leaves generic instruction asking for answer; success mainly indicated by Next puzzle button and judge's return letter. Read that letter in a later puzzle to assess feedback. At narrow browser width the held-number toolbar becomes very tall because the help text wraps into a narrow column. UI state and rendered screenshots sometimes lag each other during animations; distinguish automation/background rendering artifacts from app bugs.
