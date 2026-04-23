# Micro-Behavior Composer: Design Document

## Concept

A single-page HTML app for exploring emergent visual patterns from concurrent incremental micro-behaviors controlling a turtle on a canvas. Inspired by the BehaviorComposer's micro-behavior model — small independent processes run concurrently on shared state, producing emergent complexity from simple parts.

This is NOT a Logo programming environment. There is no Logo code. Users define a set of **micro-behaviors**, each specifying an incremental action and conditions under which it fires. All micro-behaviors run concurrently on a shared turtle state, stepping through a tick-based simulation. The visual output emerges from their interaction.

**Design the architecture with multi-turtle expansion in mind** — the turtle state, rendering, and micro-behavior binding should be structured so that adding multiple turtles later (each with their own ensemble of micro-behaviors, and inter-turtle conditions like "follow" or "avoid") requires minimal refactoring. But for this first version, there is one turtle.

---

## Core Model

### Turtle State

A single turtle has this mutable state, all floating point:

```
TurtleState {
  x: number           // canvas position (starts center)
  y: number           // canvas position (starts center)
  heading: number     // degrees, 0 = north, clockwise (starts 0)
  r: number           // red component 0–255 (starts 255)
  g: number           // green component 0–255 (starts 255)
  b: number           // blue component 0–255 (starts 255)
  a: number           // alpha 0.0–1.0 (starts 1.0)
  bgR: number         // background red (starts 0)
  bgG: number         // background green (starts 0)
  bgB: number         // background blue (starts 0)
  penWidth: number    // pen width in pixels (starts 1)
  penDown: boolean    // is pen drawing? (starts true)
}
```

All starting values are user-configurable defaults. The defaults above give white-on-black.

### Micro-Behavior

```
MicroBehavior {
  id: string              // unique identifier
  label: string           // user-readable name, e.g. "slow turn"
  enabled: boolean        // can be toggled on/off without deleting
  action: Action          // what it does
  conditions: Condition[] // ALL must be true for it to fire (AND logic)
}
```

### Actions

All actions are incremental — they add to or subtract from the current state. There are no absolute setters.

```
Action {
  type: '+FD' | '+BK' | '+RT' | '+LT' | '+R' | '+G' | '+B' | '+A' | '+BGR' | '+BGG' | '+BGB' | '+PW' | 'TOGGLE_PEN'
  amount: number            // ignored for TOGGLE_PEN
  amountDelta: number       // added to amount each time this micro-behavior fires (default 0)
  amountMultiplier: number  // multiplied into amount each time this micro-behavior fires (default 1)
}
```

Each time a micro-behavior fires, its amount updates via:

```
amount = amount × amountMultiplier + amountDelta
```

With `amountMultiplier: 1` and `amountDelta: 0` (the defaults), the amount never changes. Common patterns:

- **Linear growth** (arithmetic spiral): `amountDelta: 0.1, amountMultiplier: 1` — amount increases by 0.1 each firing: 2.0, 2.1, 2.2, ...
- **Exponential growth** (logarithmic spiral): `amountDelta: 0, amountMultiplier: 1.02` — amount grows by 2% each firing: 2.0, 2.04, 2.08, ...
- **Exponential decay** (behavior fades out): `amountDelta: 0, amountMultiplier: 0.95` — amount shrinks toward zero: 2.0, 1.9, 1.81, ...
- **Converging to steady state**: `amountDelta: 0.5, amountMultiplier: 0.99` — amount converges to `delta / (1 - multiplier)` = 50


| Action | Effect |
|--------|--------|
| `+FD N` | Move forward N pixels along current heading |
| `+BK N` | Move backward N pixels |
| `+RT N` | Rotate heading clockwise by N degrees |
| `+LT N` | Rotate heading counter-clockwise by N degrees |
| `+R N` | Add N to red component (float internally, clamped 0–255 for rendering) |
| `+G N` | Add N to green component |
| `+B N` | Add N to blue component |
| `+A N` | Add N to alpha (float internally, clamped 0.0–1.0 for rendering) |
| `+BGR N` | Add N to background red |
| `+BGG N` | Add N to background green |
| `+BGB N` | Add N to background blue |
| `+PW N` | Add N to pen width (clamp to minimum 0.1 for rendering) |
| `TOGGLE_PEN` | Flip penDown state |

Amounts can be negative. `+RT -5` is the same as `+LT 5`.

**Rendering details:**
- RGB values accumulate as floats, get `Math.round()` and clamped to 0–255 when used for drawing
- Alpha accumulates as float, clamped to 0.0–1.0 for rendering. Use `rgba(r, g, b, a)` for stroke style
- Pen width accumulates as float, clamped to minimum 0.1 for rendering
- Heading wraps modulo 360 (always kept in 0–360 range)
- Background changes apply to the entire canvas on the tick they fire (redraw background, then redraw all lines — or more efficiently, just track current background and apply it only to new drawing operations)

Actually, for background: changing the background should NOT erase previous drawing. Instead, background micro-behaviors change the "current background color" which is rendered as a filled rectangle behind all the accumulated drawing. This means background changes create a global color shift behind the existing artwork. Alternatively, and simpler: background micro-behaviors don't affect an actual background fill — they affect a state variable that other conditions can reference (e.g. "turn faster when background-red is high"), and the canvas background is set once at the start. **Let the user choose**: a checkbox "Background changes repaint canvas" (default off). When off, bgR/bgG/bgB are state variables only. When on, the canvas background updates each tick.

### Conditions

```
Condition {
  variable: 'x' | 'y' | 'heading' | 'r' | 'g' | 'b' | 'a' | 'bgR' | 'bgG' | 'bgB' | 'penWidth' | 'tick'
  operator: '>' | '<' | 'cross'
  value: number
}
```

| Operator | Meaning |
|----------|---------|
| `>` | Fires when variable > value |
| `<` | Fires when variable < value |
| `cross` | Fires on the tick when the variable crosses a multiple of value. Computed as `floor(previous / value) != floor(current / value)`. Works for both increasing and decreasing values. |

`tick` is a built-in counter that increments by 1 each tick, starting at 0. `{tick, cross, 30}` means "fire every 30th tick."

A micro-behavior with an empty conditions array fires every tick.

Multiple conditions use AND logic — all must be true.

### Canvas Boundary Behavior

When the turtle's position moves outside the canvas bounds:

- **Wrap** (default): turtle reappears on the opposite side, creating torus topology
- **Bounce**: turtle reflects off the edge (heading is mirrored) and continues drawing
- **Clamp**: turtle stops at the edge but heading continues to change (it can "unstick" when heading points inward again)
- **Ignore**: turtle continues drawing off-canvas, lines are clipped

User selects from a dropdown. Default is Wrap.

### Tick Execution

Each tick, in order:

1. Save previous state (`prevX`, `prevY`, `prevHeading`, `prevR`, ... for all variables)
2. For each enabled micro-behavior, evaluate conditions against current state and previous state (for `cross`)
3. Collect all micro-behaviors whose conditions pass
4. Apply all their actions to the turtle state (order shouldn't matter since they're all incremental — but apply them in definition order for determinism)
5. Apply boundary behavior to position
6. Clamp rendering values (RGB → 0–255, penWidth → min 0.1)
7. If penDown, draw a line from (prevX, prevY) to (x, y) in current color at current pen width
8. Increment tick counter
9. If background repaint is on and any bgR/bgG/bgB changed, update background

Run for `totalTicks` ticks (default 1000, user-configurable, suggested range 100–10000).

---

## UI Design

Use the same visual design system as the Logo Evolution Lab: Chakra Petch headings, JetBrains Mono for values/code, dark theme (with light toggle), teal/amber/lavender accent palette, card-based layout, rounded borders, subtle gradients.

### Layout

Two-column layout on desktop. Left column: canvas and playback controls. Right column: micro-behavior editor and ensemble controls.

### Left Column: Canvas & Playback

**Canvas**: 500×500px (or responsive), black background by default. Shows the drawing in progress or completed.

**Playback controls** (below canvas):
- ▶ Play / ⏸ Pause button
- ⏹ Stop (reset to tick 0, clear canvas)
- Speed slider: ticks per animation frame (1 = slow, 10 = normal, 100 = fast, "Instant" = run all ticks immediately)
- Tick counter display: "Tick 342 / 1000"
- Progress bar

**Settings row** (below playback):
- Total ticks: number input (default 1000)
- Boundary mode: dropdown (Wrap / Bounce / Clamp / Ignore)
- Background repaint: checkbox (default off)
- Canvas size: dropdown or input (400 / 500 / 600 / 800)

### Right Column: Micro-Behavior Editor

**Ensemble header**: "ENSEMBLE" with count "(5 micro-behaviors)" and buttons:
- ➕ Add micro-behavior
- 🎲 Random ensemble — with a small number input next to it for count (default 5, range 2–15)
- 📋 Copy JSON / 📥 Paste JSON (for sharing ensembles)
- 🗑 Clear all

**Micro-behavior cards**: Each micro-behavior is a card with:

- **Header row**: drag handle (for reordering), label (editable text field), enabled toggle (checkbox), delete button (×)
- **Action row**: dropdown for action type (`+FD`, `+RT`, `+R`, `+A`, etc.), number input for amount (allow decimals and negatives), number input for amount delta (label "Δ", default 0), number input for amount multiplier (label "×", default 1) — show the Δ and × fields slightly muted when at their defaults to reduce visual clutter
- **Conditions section**: 
  - Each condition is a compact row: dropdown (variable) | dropdown (operator) | number input (value) | delete (×)
  - "Add condition" button
  - If no conditions: shows "fires every tick" in muted text

Cards should be compact — you'll have up to 12+ visible simultaneously. Use a scrollable container if needed.

### Starting State Panel

Collapsible panel titled "STARTING STATE" showing all turtle state defaults as editable number inputs:
- Position: x, y (default: canvas centre)
- Heading: degrees (default: 0)
- Pen color: R, G, B (default: 255, 255, 255) — show a color swatch preview
- Alpha: (default: 1.0, range 0.0–1.0)
- Background: R, G, B (default: 0, 0, 0) — show a color swatch preview
- Pen width: (default: 1)
- Pen down: checkbox (default: on)

### Max ensemble size

Number input in the ensemble header area (default 12). Not a hard limit enforced in code — just guidance for the random generator and a soft warning if exceeded.

---

## Random Ensemble Generator

The "Random ensemble" button creates a quick starting point for exploration. Generate N micro-behaviors (where N is the count input next to the button, default 5) with:

- At least one movement action (+FD or +BK)
- At least one turning action (+RT or +LT)
- Optionally one or two color actions (+R, +G, +B, +A)
- Random amounts in reasonable ranges: FD/BK: 1–10, RT/LT: 1–30, R/G/B: 1–10, A: -0.02–0.02, PW: 0.1–0.5
- 30% chance each micro-behavior gets a non-zero amountDelta (small: ±0.01–0.5, scaled to action type) or a non-default amountMultiplier (0.95–1.05)
- 50% chance each micro-behavior gets 1 condition with a random variable and operator
- For `cross` conditions, use values like 30, 45, 60, 90, 100, 120, 180
- For `>` / `<` conditions, use values near the middle of the variable's range

---

## Presets

Include a few built-in presets that demonstrate the system's capabilities:

**"Circle"**: Two micro-behaviors — `+FD 2` (every tick) and `+RT 1` (every tick). The minimal ensemble that produces a recognizable shape.

**"Color Spiral"**: `+FD 2, Δ 0.05` (every tick), `+RT 7` (every tick), `+R 2` (every tick), `+B -1` (every tick). The linearly increasing FD amount makes each loop larger than the last, creating an arithmetic spiral that shifts from white through warm colors.

**"Log Spiral"**: `+FD 1, × 1.005` (every tick), `+RT 5` (every tick), `+G -0.5` (every tick). The exponentially growing FD amount creates a logarithmic spiral — the curve maintains constant angle to the radius, producing the form seen in nautilus shells and galaxies.

**"Breathing Square"**: `+FD 4` (every tick), `+RT 90` (when tick cross 20), `+R 5` (when heading > 180), `+G -5` (when heading < 180). Draws squares that shift color based on direction.

**"Ghost Traces"**: `+FD 3` (every tick), `+RT 11` (every tick), `+A -0.005` (every tick), `+R 3` (when a < 0.3). Lines gradually fade to transparent, with red intensifying as they disappear — creates layered ghostly traces where newer strokes overlay faded older ones.

**"Chaos Garden"**: 6–8 micro-behaviors with various conditions, amountDelta, and amountMultiplier values creating a complex pattern. Design this to look genuinely beautiful.

Presets are loadable from a dropdown in the ensemble header area. Loading a preset replaces the current ensemble and resets the canvas.

---

## Export / Import

**JSON**: The ensemble (micro-behaviors + starting state + settings) serialises to a compact JSON format. Users can copy/paste this to share ensembles. Include a "Copy JSON" button and a "Paste JSON" import.

**PNG**: Download current canvas as PNG.

**Record**: A "Record" toggle that, when enabled during playback, captures each tick's canvas state. On stop, offers to download as:
- Animated GIF (if feasible — may need a library like gif.js)
- A self-contained HTML file that replays the animation (embed the tick data and renderer)

---

## State Management

```javascript
const APP = {
  ensemble: MicroBehavior[],
  turtleState: TurtleState,
  startingState: TurtleState,     // reset target
  settings: {
    totalTicks: number,
    boundaryMode: 'wrap' | 'bounce' | 'clamp' | 'ignore',
    backgroundRepaint: boolean,
    canvasSize: number,
    speed: number,
  },
  tick: 0,
  isPlaying: false,
  drawHistory: [],                // for replay / export
};
```

---

## Architecture Notes for Multi-Turtle Expansion

Structure the code so that:

- `TurtleState` is a class/object that can be instantiated multiple times
- The tick loop iterates over an array of turtles, each with their own ensemble
- The condition system references `this` turtle's state but could later reference `other` turtles (e.g. `{variable: 'distanceTo:turtle2', operator: '<', value: 50}`)
- The canvas renderer draws all turtles' lines to the same canvas
- Micro-behaviors are bound to a specific turtle

Don't implement multi-turtle yet — just don't make design choices that prevent it.

---

## Implementation Notes

### Single self-contained HTML file

Everything in one file — HTML, CSS, JavaScript. No build tools, no frameworks. Same as the Logo Evolution Lab.

### Canvas rendering

Use a 2D canvas context. Accumulate drawing operations — don't clear and redraw each tick (that would be prohibitively expensive at 1000+ ticks). Draw incrementally: each tick, draw the new line segment on top of existing content.

For background repaint mode: maintain an offscreen canvas with the drawing, and on each tick, clear the visible canvas, fill with current background color, then composite the offscreen drawing canvas on top.

### Performance

At "Instant" speed, run all ticks synchronously and render only the final result. At interactive speeds, use `requestAnimationFrame` and run `speed` ticks per frame. The tick computation itself is trivial — the bottleneck is canvas drawing, which is one line segment per tick per active movement micro-behavior.

### No external dependencies

No libraries needed. The app is simple enough that vanilla JS handles everything. If the animated GIF export proves too complex without a library, skip it for now and just offer PNG + HTML replay.

---

## Visual Design

Match the Logo Evolution Lab aesthetic:

- **Fonts**: Chakra Petch for headings and labels, JetBrains Mono for values and data
- **Colors**: Dark background (#0a0a0f), cards with subtle borders (#1a1a2e), teal accents (#2dd4bf) for primary actions, amber (#f59e0b) for warnings/secondary, lavender for tertiary
- **Cards**: Rounded corners (8px), subtle inner shadow or border, slight background gradient
- **Buttons**: Ghost style (transparent background, colored border/text) for secondary actions, filled for primary
- **Inputs**: Dark inset fields with monospace font for numeric values
- **Micro-behavior cards**: Compact, clearly bounded, with the action type shown prominently (maybe the action name as a colored chip/badge)
- **Theme toggle**: Light/dark mode switch in the header

Title: "Micro-Behavior Composer" with a subtitle or tagline like "Emergent patterns from simple rules"
