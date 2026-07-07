# Tiny Mind — Guide Session Kickoff (vg-core event extension + trilogy guide)

Dedicated session. Start from `voice-guide-prompt-v3.md` (the vg-core porting doc) plus
this addendum. Two deliverables, in order: (1) a vg-core capability upgrade — the event
bus — tested app-agnostically; (2) the Tiny Mind guide built on it, across all three
apps in the mega shell. Engine changes must stay additive (47-PASS baseline + mega
suites stay green; gradcheck and G1 parity untouched).

## 1 · vg-core upgrade: hybrid tour + event architecture

vg-core today is tour-driven (golden paths). Tiny Mind's teachable moments are
EMERGENT: the held-out floor arriving, the parroting badge, a busted clue, the
name-control verdict. The upgrade:

- **Event bus**: `vg.on(eventName, lineSpec)` where lineSpec = { lines (normal +
  little-kid variants), priority, cooldownMs, once, condition(fn) }.
- **Priority classes** through a single attention manager (one speech/text channel):
  `verdict` (preempts current line), `moment` (queues next: floor, forgetting-visible),
  `ambient` (dropped if anything is pending: step ticks). Repeats gated by cooldown;
  big teaching moments are once-per-session.
- **Tour steps that advance on events**: a step may declare `until: 'trainStarted'` —
  the tour waits on the world, not on timers. (If v3's step-advance conditions already
  cover this, document the mapping instead of adding a parallel mechanism.)
- **Commentary tracks**: a timed beat sequence opened by an event (see the training
  window below), interleaving with event beats through the same attention manager,
  canceled on navigation away.
- Voice via the existing `speak()` seam (Web Speech behind a toggle, per the Hunt);
  text bubbles are the PRIMARY channel — grandkid devices vary and speech is optional.
- Tests first, app-agnostic: fire synthetic events → assert queueing, preemption,
  cooldowns, once-flags, tour-until advancement. This is the reusable deliverable;
  future apps (Specimens, Mind Maker) will want emergent-event narration too.

## 2 · Event hooks to emit (worker → main → vg; additive)

- Nursery: `trainStarted`, `stepTick(step, loss)`, `floorReached` (zogHeld stable at
  min — the worker's existing arc detection), `parrotingBadge`, `forgettingVisible`
  (base drift beyond threshold), `sampleReady(step, text)`, `trainDone`, `exportDone`,
  `storyRejected(reasons)`, `storyAccepted`.
- Microscope: `captureDone`, `ablationVerdict(meanΔ, maxΔ)`, `neuronSelected`,
  `attentionRowPainted`.
- Hunt: `clueProposed(kind)`, `clueBusted`, `clueProved`, `nameControlVerdict(huntable)`,
  `questDone(score)`.
- Shell: `modelLoaded(app)`, `tabChanged`.
Bridge note: guides live per-frame (each template carries vg inline — no fetches in the
artifact); the shell only relays two preferences over the existing RPC: guide on/off
and little-kid mode. Store both under the `tm-` prefix.

## 3 · Tours (golden paths)

- **Nursery first-run** (the front door): invent the character → pre-flight huntability
  check (below) → ghostwrite 3 stories → read one aloud together → start raising
  (until: trainStarted) → commentary track → ask it for a story (the payoff) →
  "want to find WHERE it keeps Zog?" → hand off to the Hunt.
- **Hunt quest walkthrough**: guess-o-meter → clue → CHOIR FRAME (see scripts) →
  switch-off test → verdict → scoreboard.
- **Microscope orientation** (short, unlocked framing: "the open lab").
- **Starter-pack tour** (artifact edition only): "catch the brain" — copyable starter
  zip URL, drag-in, persisted-trainee note ("next time it'll already be here").
- Every tour has a little-kid variant; tours are skippable and resumable.

## 4 · Script content requirements (from the design sessions — these are the pedagogy)

- **Choir frame BEFORE the first bust** (mandatory ordering): "a fact in this mind is
  like a song in a choir — mute one singer and the song survives; mute the front row
  and it collapses." Then busted single-unit clues land as confirmations, not failures.
  The E5/Hunt data guarantee busts (single heads/neurons: 55.6→52–56%; layer team:
  55.6→22.8%), so the frame is load-bearing.
- **Training-window commentary track** (~4.3 min): timed beats (what the lines mean;
  the two held-out lines are "secret Zog stories" and "ordinary stories"; train-loss
  hidden by default) interleaved with event beats — floorReached: "it just learned Zog
  as well as it ever will; keep going and it starts parroting its storybook";
  parrotingBadge and forgettingVisible each get one clear line.
- **Surprise-meter language**: loss is "how surprised the model is"; never say "loss"
  in little-kid mode.
- **Crowd-of-100 toggle** (built alongside the guide or as a prior micro-task): the
  guess-o-meter and ablation before/after rendered as 100 dots colored by piece;
  bars remain as the toggle's other state. Guide narrates in crowd language when the
  toggle is on ("38 of its 100 guesses say ' was'"). For multi-piece answers the crowd
  applies per piece — the per-token breakdown stays the honest display, and the
  HEADLINE score is length-normalized (product^(1/n), "average confidence per piece"),
  with the raw product visible in the breakdown.
- **Pre-flight huntability check** (Nursery character sheet; small engine addition,
  additive): (a) piece-count each attribute's answer word in tok512 — warn on
  multi-piece ("'unicorn' is 4 pieces — hard to hunt; 'tree' is 1"); (b) probe the BASE
  model's p(answer | predictor context) before training — if already high, it's a
  collocation ("the mind knew that before it ever met Zog — pick a stranger fact to
  bury"). Uses only existing forward machinery.
- **Name-control explanation lines** for the Hunt's verdict ("we swapped the name and
  the answer stayed — this fact isn't really about Zog").
- **Honesty ritual** (once per session, staged as an exhibit not a lecture): "this mind
  needed fifty stories and a hundred readings to learn Zog. You learned Zog from one.
  Minds like this don't learn the way you do — who's the better learner, and why?"
- Tone: the guide may present itself as "a mind too — a much bigger one" (thematic and
  honest) — KEN TO APPROVE before scripting around it.

## 5 · Tests

- vg event-bus suite (app-agnostic, per §1).
- Per-app: synthetic event streams → expected line sequences (including priority and
  cooldown behavior); tour-until advancement in jsdom; little-kid variant coverage
  check (every scripted line has one).
- No regression: existing PASS counts monotone; ablate-absent forward still
  bit-identical (guide hooks must not touch the parity path).

## 6 · Open decisions for Ken (batch at session start)

(1) Guide persona: "bigger mind" framing — yes/no. (2) Voice default: off with a
prominent toggle, or on for little-kid mode? (3) Front-door inversion in the shell
(Nursery-first, bay demoted to a "workshop" tab) — do it in this session or a follow-up?
(4) Does the commentary track also run for scrubber playback (Arc kickoff), with
compressed timing?
