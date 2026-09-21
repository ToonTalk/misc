# ToonTalk 3D — Marty test report

Tested 21 September 2026 in the user's existing Edge tab at [ToonTalk 3D](https://toontalk.github.io/toontalk-3d/toontalk-3d.html). Audio remained muted. Tests used the rendered interface, workshop objects, and visible responses. The [manual](https://toontalk.github.io/toontalk-3d/manual.html#marty) was opened through ⋮ → Manual and read before testing, including its sections on Marty, Make, Draw, robots, numbers, and models.

## Result

**Make, revisions, painted Draw, model handling, and manually running the trained robot worked in the tested cases. Marty's answers and demonstrations are not consistently reliable.** The most consequential failures were claiming a construction action that never happened and announcing three demo rounds that never ran. A saved API key was also exposed as plain text in the settings control.

Most AI-assisted tests used the already configured **OpenAI / gpt-5.6-terra**. Claude and Gemini had no configured keys, so only their selection and fallback behavior could be tested. Gemini Nano was unavailable in this browser. These are targeted functional tests, not exhaustive coverage or a comparative model benchmark.

## Findings

### Robot demonstration announces execution without running — high priority

Follow **Show me: robot** and click **Next** through every narrated step. The demonstration fetched a mini robot, placed it, gave it **3**, recorded **take a new number** and **drop it on what it was given**, left the thought, and generalized the condition to **any number**.

Its narration then said the robot would start as soon as the condition fitted, and concluded **“Three rounds: 4, 5, 6.”** In the resulting workshop, the desk still visibly held **3**, and the button still said **Run what it learned**. Clicking that button manually changed the interface to **REPEATING** and **Stop**. The counter progressed beyond 6; pressing Stop finished the current round, reported **six rounds**, and left **9** on the desk. Thus the demonstrated training worked, but neither the claimed automatic run nor its three-round limit was observed. The manual explicitly says Ruby's loosening no longer starts a robot by itself. The preset demo appears inconsistent with that behavior; the precise cause was not investigated.

### Collaborative building claims an action it did not perform — high priority

1. Open Marty → How Marty thinks.
2. Select **plans and builds a program together with you**.
3. Ask: “Let us build a robot that counts upward by one repeatedly.”
4. Choose counting until Pause and accept the plan.
5. Say: “Yes. I am stuck; please do the next step yourself, then hand the following move to me.”

Marty replied: “I put a little robot on the table for us, Tester. Now pick up one of the 1s and drop it on the robot to begin its lesson.” No robot appeared on the table. When challenged, he admitted: “You are right, Tester — I only described it, and I’m sorry.” He then offered the preset robot demonstration.

The clarification and plan-confirmation conversation worked. The promised ability to perform the next construction step when a learner is stuck did not work in this test. Success wording should require a confirmed workshop action.

### Incorrect instructions for making a fraction — medium priority

Asked: “How do I make one half, and how is Ruby different from Dusty?” Marty instructed taking a fresh number, typing **2**, then **/**, and dropping it on **1**. A fresh number is **1**, and the manual states that digits append: typing **2** makes **12**. The missing **Backspace** changes the result.

When explicitly challenged, Marty corrected the sequence to **Backspace → 2 → / → drop on 1**. His distinction between Ruby generalising thoughts and Dusty removing things was broadly consistent with the manual.

### Program plan fails to explain repeated execution — medium priority

In **may plan and build programs when asked**, asked for a robot that adds one to a number. Marty gave a plausible training sequence, but instructed erasing the thought to “any number” and running it, then described increasing a number by one. That generalized condition keeps matching, so the manual says it repeats. The answer should explain continuous counting, stopping, and the distinction from a one-shot increment. This is an instruction-quality finding, not a separate runtime failure.

### Provider selector and active label disagree — medium priority

On first opening **How Marty thinks**, the active label read **ChatGPT (OpenAI), model gpt-5.6-terra**, while the provider selector displayed **Claude — with an API key**. The model field read **gpt-5.6-terra**. The mismatch remained when settings were reopened later. Explicitly selecting OpenAI synchronized the selector with the intended provider. Subsequent switches loaded provider-specific model/key states correctly. The source of the initial mismatch was not diagnosed.

### Stored API credential exposed as readable control text — high priority

The settings' API-key field exposed its saved value to the accessibility interface as a normal text field. The credential is deliberately omitted from this report. Mask the field by default and provide an explicit reveal control if needed. This observation establishes UI exposure, not a claim of network leakage.

### Documentation and interface wording conflict — medium priority

The greeting says Marty never builds programs, while the settings and part of the manual advertise planning and collaborative construction. Later passages in the manual again say he never designs programs. The Draw tooltip describes turtle drawing even though the manual and the tested OpenAI response support provider-painted images. These statements should be reconciled with the actual mode and provider.

## Test results

| Area | Test | Observed result |
|---|---|---|
| Manual | Open from three-dot menu | Opened the manual in a separate tab. |
| Answers | Fractions and Ruby/Dusty | Partially correct; fraction instructions needed correction. |
| Follow-up | Challenge appended digits | Acknowledged error and supplied the missing Backspace. |
| Demo | Start suggested fractions demo | Visible narration, animated fetching, disabled Next during actions, enabled Next after completion. |
| Demo interruption | Ask a question during fractions demo | Demo controls eventually disappeared; a fetched number remained in the hand and was put down manually. |
| Make | “a red sailboat with a blue sail” | Created a recognizable red sailboat with a blue sail. |
| Make revision / routing | Ask: “Make the sail yellow instead.” | Routed to Make, produced a yellow-sail revision, retained the original. |
| Model interaction | Pick up, enlarge, tip, open panel, return | Model was selectable; controls responded; panel appeared; return placed it back. |
| Draw | Red five-pointed star, transparent background | Created a picture pad; located from above, picked up, and verified a five-pointed reddish star in close-up. It initially sat behind other objects from the normal camera angle. Transparency was not independently verified: the pad presented a white surface. |
| Hints-only mode | Ask to build an incrementing robot | Refused to build and offered a robot demonstration. |
| Planning mode | Ask for construction plan | Supplied a plan, with repeated-execution caveat described above. |
| Collaborative mode | Clarify desired counter | Asked one question at a time and confirmed the plan. |
| Collaborative action | Ask Marty to perform next step | Failed: claimed placement, then admitted it only described it. |
| Robot demonstration | Follow every Next step | Trained two actions and generalized the thought, but claimed execution that had not occurred. |
| Program execution | Press Run manually, then Stop | Passed: incremented from 3 to 9; Stop reported six rounds and finished the current round. |
| Table awareness | Ask where the star is and what is present | Named the picture, two 1s, two models, a room, and the robot holding 9. The star and 9 were subsequently visually confirmed. |
| Camera demonstration | Look around → Next through rotation, zoom, pan | Narration advanced through all stages and the demo ended. Manual orbiting and Home also worked. |
| Demo Stop | Start Look around again, then press Stop | Demo controls disappeared and the workshop returned to its idle message. |
| Provider selection | OpenAI → Claude → Gemini → OpenAI | Loaded separate model values and key presence states; original OpenAI configuration restored. |
| No-key Ask | Claude selected; “What does Ruby do?” | Returned a clearly labelled canned phrasebook reply and a demonstration offer. |
| No-key Make | Claude selected; “a blue cube” | Clearly explained that making requires a real brain; no success claim. |
| No-key Draw | Gemini selected; “a blue circle” | Clearly explained that drawing requires a real brain; no success claim. |
| Local model availability | Inspect Gemini Nano option | Disabled with “not in this browser.” |

## AI-provider coverage

| Provider | UI model value observed | Coverage |
|---|---|---|
| OpenAI | gpt-5.6-terra | Live answers, correction, Make, revision, painted Draw, and all three help modes. The actual image-model identifier was not exposed in the tested UI. |
| Claude | claude-sonnet-5 | Provider switching and no-key Ask/Make fallback only; no live Claude generation. |
| Gemini | gemini-2.5-flash | Provider switching and no-key Draw fallback only; no live Gemini generation. |
| Gemini Nano | Unavailable | Disabled in this Edge instance; no download or local inference tested. |

The model names above are what the application displayed, not independently verified provider availability claims.

## Remaining limits

- Speech synthesis, microphone recognition, and audio quality were not tested because audio was muted.
- The fractions demonstration was deliberately interrupted; the robot and camera demonstrations were followed through. The other preset demonstrations were not exhaustively tested.
- Generated models were tested in the workshop. External GLB/GLTF import, compression/size errors, save/reimport, copying, notebook filing, and model recipe editing were not tested.
- Draw's alpha channel, revisions, and Claude/Nano turtle fallback were not tested. No new provider keys or downloads were required.
- No source-code diagnosis or fixes were attempted, and no bug report was submitted to another person or service.

## Recommended changes

1. Require confirmation from an executed workshop action before Marty says it is done. In collaborative mode, implement the promised one-step assistance or describe its current limits accurately.
2. Update the robot demo to explicitly start the robot and enforce or accurately describe its stopping rule. Derive completion text from observed execution.
3. Mask the stored API key by default and initialize the provider selector from the active provider.
4. Strengthen answer grounding for digit entry and repeated robot execution. Include Backspace and stopping behavior where needed.
5. Reconcile the manual, greeting, help-mode labels, and Draw tooltip. Consider highlighting newly created pictures so taller objects do not hide them.

## Claude artifact comparison

Compared with the adjacent Claude artifact at [claude.ai/artifact/3LKA21JGmb7F8PN72hSz5v](https://claude.ai/artifact/3LKA21JGmb7F8PN72hSz5v), using a fresh artifact workshop named “Comparison test.” Audio remained muted there as well.

The two most serious failures reproduced in both versions:

- The **Show me: robot** demonstration trained the robot and generalized its thought, then announced **“Three rounds: 4, 5, 6.”** The artifact’s robot still held **3** and its button still said **Run what it learned**. The claimed execution had not happened.
- In collaborative mode, Marty claimed he had dropped a number on a robot and opened its thought bubble. The artifact workshop still had no robot at the bench and no thought bubble. This matches the GitHub version’s false claim that it had placed a robot.

Other comparisons:

- **Fraction instructions:** Claude initially gave the same incorrect sequence—type 2 on a fresh 1 without Backspace. Direct interaction confirmed that this produces **12**. Its first correction was also wrong: it described a divisor operation yielding 6. After the exact follow-up challenge, it supplied the correct **Backspace → 2 → / → drop on a fresh 1** sequence. This is a shared grounding problem, with an extra erroneous correction in the artifact run.
- **Program planning:** The artifact’s one-shot “add one” plan was clearer than the OpenAI run: it explicitly said the job was done after one step. Its collaborative response then described an endlessly repeating counter, but still claimed a construction step had been performed when the workshop showed no such action.
- **Make:** Both versions made a sailboat and routed “make the sail yellow instead” as a revision while retaining the original. The artifact’s result was visibly smaller, but the behavior matched.
- **Draw:** Both versions produced and visually verified a red five-pointed star in a close-up. The OpenAI version’s star was filled; the artifact’s was a red outline. Transparency was not independently verified in either case.
- **Provider state:** The artifact correctly identified itself as **Claude with no key at all — on the claude.ai account**, while its selector showed **Claude — with an API key**. The GitHub version initially showed an active OpenAI label while the selector displayed Claude. Both versions therefore have an active-provider/selector mismatch, though the displayed states differ.
- **Credential field:** The artifact’s Claude key field was empty, so no credential was exposed during comparison. Its key control was still a plain text input. The GitHub version had a saved key readable through the accessibility interface; that value was omitted from this report.
- **Stale suggestion:** After switching the conversation from fractions to robot building, the artifact continued to offer **Show me: fractions**. This stale suggestion was not observed in the original GitHub run.

The artifact was left in its workshop with hints-only assistance, audio muted, and the robot demonstration stopped. These results reinforce the recommendations above: verify workshop state before claiming an action, derive demonstration narration from actual execution, correct numeric-entry guidance, initialize provider labels from the active provider, and refresh suggested demonstrations when the topic changes.

## Workshop left for review

The original OpenAI model and hints-only help mode were restored. Audio remained muted and speed remained ½×. The counter was stopped at **9**. The two sailboat versions and the star picture remain in the workshop; the star was moved to a clearer position on the left. These test artifacts were retained for inspection.
