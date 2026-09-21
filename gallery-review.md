# Published ToonTalk 3D gallery review

Reviewed 19 September 2026: https://toontalk.github.io/toontalk-3d/gallery.html

## Scope

Explored the published gallery, inspected its 57 cards and internal link targets, tested category and prerequisite navigation, and launched the spark lesson and album. Ran the spark lesson at Instant speed, reset it, and ran it again. Audio remained muted. This is a gallery and representative-launch review, not a runtime certification of all 57 programs. Mobile and screen-reader operation were not tested.

## What works well

- Category navigation (Games and Meta) and the Bouncing prerequisite link reached the appropriate sections/cards. The gallery contained no unresolved internal anchors or links pointing to localhost.
- The two tested example links opened the corresponding published worlds.
- The spark lesson completed, reporting 21 runs including the finishing robot. Its dots remained after the spark hid. Reset restored the lesson, and it completed again.
- The gallery has a useful teaching structure: prerequisites, instructions, program size, and particularly the concrete “Change and predict” prompts.
- Labelled paths such as “letters › hide” and “my spark bird”, together with the robot team's “next member” button, make the lesson easier to inspect.
- No warnings or errors were present in the captured gallery console log.

## Confirmed problems

### 1. Album instructions describe a different example

Card 39, “An album”, describes pictures on a nest being removed by a robot, says to give a work box to the robot, and asks the learner to add a picture to the nest. Its own statistics say zero robots and zero steps. Opening it shows picture notebooks and a spare picture; the actions panel says “no robot at the bench” and Start is disabled.

Replace the description and activity with notebook exploration: turn pages, take a picture from a page, and add a picture to the album. Make the expected initial objects explicit.

https://toontalk.github.io/toontalk-3d/gallery.html#e39

### 2. Reset directions point to the wrong side

The gallery repeatedly says “Start over is on the card at the right.” In the opened workshops, “Start this world over” is on the upper-left title card. The spark completion message repeats the same incorrect direction.

Refer to the button by its exact label, without a positional description that can become stale across layouts.

### 3. Reset duplicates the spark introduction

Reproduction: open card 5, run to completion, then click “Start this world over”. Marty's panel opens with two identical copies of the lesson introduction in its conversation. The program still resets and runs correctly.

Replace the previous introduction when resetting, or avoid inserting it again when it is already the latest message.

https://toontalk.github.io/toontalk-3d/gallery.html#e5

## Recommended improvements

1. **Separate learning difficulty from program size.** Robot and step counts are useful technical facts, but can discourage learners unnecessarily. Resort Infinity lists 63 robots even though its activity asks the learner to train a particular robot. Distinguish “try it”, “change it”, and “understand/build it”.
2. **Offer a short beginner route with optional branches.** Random colour appears as card 6 under First steps but has a 28-step robot and introduces list splitting, indexed selection, and colour messages. Mark this as an optional challenge or explain the conceptual jump.
3. **Show the distinguishing result more prominently.** Several thumbnails show almost identical whole workshops. A closer view of the result, or a before/after pair, would make choosing an example easier.
4. **Improve navigation through 57 cards.** Add search or concept filters, a persistent category selector/back-to-top control, and optionally a “tried” marker.
5. **Give links specific accessible names.** Repeated “Open in the workshop” links would be clearer as “Open An album in the workshop”, etc. Indicate that these open new tabs; repeated exploration currently accumulates workshop tabs.
6. **Separate prerequisite links visibly.** Multiple prerequisites currently read like adjacent words. Commas, bullets, or small labelled chips would help.
7. **Standardise run instructions.** Some explicitly say to press Start, while others stop after “give the box to the robot”. Each should state the complete sequence and what success looks like. This is a clarity recommendation; I did not run every card to prove a missing step.
8. **Keep guidance with its example.** Generate gallery instructions and in-workshop introductory text from shared metadata where practical, reducing mismatches like the album and reset directions.

## Overall assessment

The gallery is a useful improvement over a folder of example files: it gives children a route, a reason to try each program, and something to investigate. The most urgent fixes are the album instructions and reset wording. Next, focus on helping children choose a manageable activity and recognise its successful result.
