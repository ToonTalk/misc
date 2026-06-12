# The Atelier — Specification v1

*A single-file web app where students (age ~9 and up) learn constructionism by constructing small constructionist agents: little software minds that make things (turtle drawings and short poems), exhibit them, receive critique, reflect in a journal, and improve over rounds. An optional Advanced "Science Corner" lets older students run controlled experiments on agent minds.*

Working title: **The Atelier**. Alternate: MindMakers. (Final name is the owner's call; use "Atelier" in code identifiers.)

---

## 1. Vision and pedagogy (read this first)

The app is an object-to-think-with at two levels:

1. **The agent's artifacts** (drawings, poems) are constructed, public, shareable objects — classic constructionism.
2. **The agent's mind itself** is a constructed, public, editable object. When an agent stagnates, loops, or improves, the student debugs its *learning process*: its goals (Spark), its skills (Hands), its self-perception (Eyes), its reflection habits (Inner Voice), its memory, and its social manner. This lifts Papert's "debugging as the heart of learning" one level up.

Design pillars that every feature must serve:

- **Glass box, never black box.** Every part of an agent's mind is plain text the student can read and rewrite. No hidden prompts that shape behavior (system scaffolding is visible via a "peek under the hood" affordance — see §7.6).
- **Make → exhibit → critique → reflect → improve** is the core loop, for the agent *and* for the student (dual reflection, §10).
- **Society of Mind lineage, in plain words.** Maker, Eyes, Critic, Memory are little agents in a tiny society. Small optional "Big Idea" bubbles connect features to Papert and Minsky in child-readable language (§7.5).
- **Amplify, don't substitute.** The student is the director, editor, and co-maker. The app repeatedly hands agency back: edit the artifact, edit the lessons, moderate the crit, decide what "better" means.
- **Lowest possible age floor** for the main studio: target reading age ~9 (UK Year 5 / US Grade 4). Science Corner is gated behind an Advanced toggle and may use harder language (~14+).

---

## 2. Audience and modes

| Mode | Audience | Gate |
|---|---|---|
| Studio (default) | ~9+ | none |
| Advanced / Science Corner | ~14+ or teacher-led | Settings toggle "Advanced mode" (no PIN in v1; keep it simple) |

Copy rules for Studio mode: short sentences; concrete verbs; icon + word on every button; no jargon ("prompt" → "instructions", "parameters" → "settings", "iteration" → "round"). Science Corner may use words like "variable", "control", "hypothesis", "metric" — that vocabulary is part of its point.

---

## 3. Domain model

All data lives client-side (localStorage + export/import). Schema version key: `atelier.v1`.

```ts
// Pseudotypes — implement in plain JS with JSDoc, no TypeScript build step.

Agent {
  id, name, createdAt,
  look: { emoji, color },            // avatar
  medium: "turtle" | "poet",         // chosen at creation; not switchable in v1
  anatomy: {
    spark: string,                   // what it longs to make, in its own words
    hands: string,                   // maker instructions (prompt) used each round
    eyes: { enabled: boolean, looking: string },  // how it examines its own work
    innerVoice: string,              // reflection instructions
    studioManner: {
      presenting: string,            // how it titles work & writes artist statements
      critic: string                 // persona it adopts when critiquing others
    }
  },
  memory: {
    journal: JournalEntry[],         // one per round, agent-written
    lessons: Lesson[]                // distilled, max 5 active; student-editable
  },
  stats: { roundsRun: number }
}

JournalEntry { round, text, createdAt }
Lesson { id, text, active: boolean, source: "agent" | "student" }

Work {
  id, agentId, round, medium,
  payload: { code?: string, poem?: string },   // turtle JS or poem text
  thumbnail: string|null,            // PNG dataURL (turtle only; poems render as typographic cards live)
  title: string, artistStatement: string,
  selfRating: number|null,           // 1–5, agent's own
  critiques: Critique[],
  humanEdited: boolean,              // true if student revised the payload
  createdAt
}

Critique { from: "student" | agentId, text, createdAt }

CritSession { id, participantAgentIds[], workIds[], transcript: TranscriptTurn[], createdAt }

Experiment {            // Science Corner only
  id, name, question,                       // student's question/hypothesis
  baselineAgentId, variantAgentId,          // variant = clone with ONE change
  changedPart: string,                      // which anatomy card differs
  rounds: number,
  results: { agentId, round, workId, selfRating, judgeRating, novelty }[],
  judgeSpec: { prompt: string, providerRole: "judge" },  // fixed across the experiment
  createdAt
}

Settings {
  schemaVersion: "atelier.v1",
  advancedMode: boolean,
  runtimeMode: "artifact" | "standalone",   // auto-detected, overridable
  providers: { anthropicKey?, openaiKey?, googleKey? },   // standalone only
  roleModels: { maker, eyes, judge, reflect },            // role → {provider, model}
  budgets: { maxRoundsPerSession, maxTokensPerCall },
  ui: { language: "simple" | "advanced" }   // copy register, follows advancedMode by default
}
```

Persistence rules: write-through to localStorage after every mutation; never lose a partially completed round (persist each phase as it finishes). Full-state export/import as one JSON file. Individual agent export as a "trading card" JSON (§11).

---

## 4. The two media

### 4.1 Turtle drawings

- Canvas: 512×512, white background, turtle starts at center facing up.
- The agent's Hands produce **JavaScript restricted to a fixed turtle API** (no other globals). API surface, exactly:
  - `forward(n)`, `back(n)`, `left(deg)`, `right(deg)`
  - `penUp()`, `penDown()`, `penColor(css)`, `penWidth(w)`
  - `goTo(x, y)` (no drawing if pen up), `home()`, `setHeading(deg)`
  - Plain JS `for`/`while`/functions/`Math.*` are allowed.
- Execution: inside a **sandboxed iframe** (`sandbox="allow-scripts"`, no same-origin), code injected via postMessage, wrapped with: step counter cap (e.g. 100,000 turtle ops), wall-clock timeout (3 s), try/catch reporting errors back as structured messages. The iframe owns the canvas; on completion it posts back a PNG dataURL snapshot plus op count.
- Animated drawing: replay the recorded op list in the visible studio canvas at adjustable speed, so students *watch* the turtle draw. (Record ops in the sandbox; animate in the parent. This also means the screenshot harness can verify the final static canvas deterministically — render final state instantly for tests via a `?instant=1` style flag or exposed JS hook.)
- Errors are part of learning: a runtime error becomes a visible event the agent reflects on ("my drawing crashed at step 3 — here is the error").

### 4.2 Short poems

- Constraints (visible to the student, editable in Advanced mode): ≤ 8 lines, ≤ 60 words, age-appropriate.
- "Rendering" = a typographic card (nice font, agent's color as accent). No image generation.
- Eyes for poets need **no vision call**: the "looking" step re-reads the poem with the Eyes prompt ("read your poem out loud in your head; what works, what clunks?"). Cheap and fast — poets make a good low-cost on-ramp.
- Cross-media crits are allowed and encouraged: a poet critiquing a drawing (it receives the image if its critique call uses a vision-capable model, otherwise the drawing's title + artist statement + the maker's code comments).

---

## 5. The studio round (core loop — build this first)

A round for one agent, with live phase-by-phase UI (each phase appears as a card filling in; nothing happens invisibly):

1. **Make.** Call LLM (role: maker) with: Hands prompt + Spark + active Lessons + **most recent journal entry** (so "next time I want to try X" actually reaches the next Make) + last work's payload (if any) + any pending critiques + (if humanEdited last round) a plain-language diff note: "A human revised your work. Here is what changed." Output: turtle code or poem, plus a one-line intention.
2. **Render.** Turtle: sandbox run → animated replay → thumbnail. Poet: typographic card.
3. **Look** (if Eyes enabled). **Comparative looking:** the call receives the *previous* work (image for turtle, text for poem) plus the agent's previous observations, then the new work, and is asked what changed and whether it moved closer to the Spark. First round falls back to single-work looking. Comparison is governed by an "Eyes remember" sub-toggle on the Eyes card (default on) — it doubles image tokens per Look and is a first-class Science Corner variable (does an agent that can perceive its own trajectory improve faster?). If Eyes disabled, skip — the agent reflects "blind."
4. **Exhibit.** Work goes on the Gallery Wall with agent-written title + artist statement (Studio Manner: presenting).
5. **Critique.** Optional this round: the student writes a critique, and/or invites 1–3 other agents to respond (each uses its own Studio Manner: critic persona). **Critic memory:** when an agent critiques work by an author it has critiqued before, its call includes its own previous critique of that author's work, so it can notice growth ("you took my wish about colour seriously"). Kindness rules are hard-coded into every critic call: name something specific that works, one wish, never mock (see §12).
6. **Reflect.** Call (role: reflect) with Inner Voice prompt + this round's intention, observations, critiques, errors + **its previous journal entry** ("if you promised yourself something, say whether you did it") → journal entry (≤ 120 words, first person).
7. **Distill.** Every N rounds (default 3) or on demand: compress journal into ≤ 5 active Lessons. **The student can edit, delete, or pin lessons, and can add their own** (source: "student"). Lessons are the agent's only long-term memory injected into Make — this is deliberately legible.

Acceptance criterion for the loop (M1 milestone): a fresh turtle agent with the default "spiral garden" spark shows *visible, journal-explained* change across 5 rounds, with every phase inspectable.

---

## 6. The Crit Room

- Student picks 2–4 agents and 1 work each (or runs "exhibit latest").
- Sequential turns: each agent presents (presenting manner), then others critique (critic manner), student can interject as moderator with their own turns.
- Cross-media welcome. Transcript saved to CritSession; relevant critiques are attached to Works so they feed the authors' next rounds.
- One LLM call per turn; budget meter visible (§13.4).

---

## 7. UI — screens and layout

Single-page app, top-level nav as big icon tabs. Mobile-friendly but desktop-first (school laptops).

1. **Studio (home).** Your agents as large cards (avatar, name, medium, spark snippet, "Run a round" button). "Make a new mind" button → creation flow.
2. **Agent creation flow.** Three friendly steps: pick medium (draw / write), pick a look (emoji + color), then choose a starter mind from ~6 templates per medium (each template fills all anatomy cards with editable text) or "start from scratch". Templates ship in-app (§7.4).
3. **Mind editor.** The six anatomy cards laid out as physical-feeling cards: Spark, Hands, Eyes (with on/off switch), Inner Voice, Memory (journal list + lessons editor), Studio Manner (two sub-cards). Every card: plain-language caption + edit-in-place textarea. A small "Big Idea" bubble per card (§7.5).
4. **Round runner.** Vertical timeline of phase cards filling in live (Make → Render → Look → Exhibit → Critique → Reflect). The turtle canvas is the hero element; replay speed slider; "Edit this drawing/poem" button opens the payload editor (code or poem) with live re-render — saving marks humanEdited.
5. **Gallery Wall.** Masonry of works (thumbnails / poem cards) with title, agent avatar, round number. Click → detail: artist statement, critiques, "add your critique", "invite agents to respond", "export this wall" (§11).
6. **Crit Room.** Chat-like transcript with agent avatars; moderator input box.
7. **Notebook.** The *student's* journal (§10).
8. **Science Corner.** Only visible in Advanced mode (§9).
9. **Settings.** Runtime mode + provider keys (standalone), role→model table, budgets, Advanced toggle, full export/import, "start over" (with confirm).

### 7.4 Starter minds (ship 12: 6 turtle, 6 poet)
Write these carefully — they are the pedagogical seed corn. Examples: *Spiral Gardener* (turtle; loves spirals, wants them to feel like plants), *Rain Painter* (turtle; wants drawings that feel like weather), *Tiny Architect* (turtle; symmetric buildings), *Haiku Snail* (poet; tiny poems about small things), *Question Asker* (poet; every poem ends with a question), *Kind Critic* (either; mild maker, superb critic — exists to show Manner matters). Each template includes all six anatomy texts in child-friendly first person ("I love spirals because…").

### 7.5 Big Idea bubbles
Small "?" buttons that open one-paragraph, age-9 explanations linking the feature to its lineage, e.g. on Memory: "A scientist named Marvin Minsky thought a mind might be lots of little helpers working together. Your agent's memory is one helper. What happens if you take it away?" Keep to ~10 bubbles total; list them in an appendix of the implementation (content provided inline in code, easy to edit).

### 7.6 Peek under the hood
Every LLM call gets a collapsible "what we actually sent" view (final composed prompt, response, token estimate). Collapsed by default in Studio mode, expanded by default in Advanced mode. This keeps the glass-box promise honest.

---

## 8. Human co-construction

- **Edit the artifact:** code editor (textarea + monospace; no CodeMirror dependency in v1) or poem editor, with instant re-render. Saving sets humanEdited and stores the pre-edit version so the next Make call can include a short "what the human changed" note (compute a simple line-diff summary in JS; for poems, before/after).
- **Edit the mind:** all anatomy cards, any time.
- **Edit the memory:** lessons are student-curatable (the most underrated control surface — call this out in the Notebook prompts).

---

## 9. Science Corner (Advanced mode)

Purpose: controlled experiments on minds; the hidden curriculum is *operationalizing "better"* and meeting Goodhart's law honestly.

- **New experiment wizard:** pick a base agent → app clones it twice (baseline + variant) → student changes **exactly one** anatomy part on the variant (the wizard enforces one-change-only and records `changedPart`; toggles count as parts: Eyes on/off, Eyes-remember on/off) → set rounds N (default 6, max 12) → write the question ("Will losing its Eyes make its drawings drift from its Spark?").
- **Run:** both agents run N rounds back-to-back with identical scheduling; no crits from other agents during an experiment (control the variables); progress bar with per-round cost estimate before starting.
- **Metrics per round:**
  - *Self-rating* (agent's own 1–5, from Reflect phase).
  - *Judge rating* (1–5): a **fixed judge prompt + fixed model for the whole experiment** scores the work against the Spark. Show the judge prompt; let students edit it *before* the run, never during.
  - *Novelty:* turtle — Hamming distance between 8×8 average-hash (aHash) of consecutive thumbnails, implemented in ~30 lines of JS, no deps; poet — 1 minus Jaccard similarity of word sets between consecutive poems.
- **Results view:** two timeline strips of thumbnails/cards side by side; line charts of the three metrics (hand-rolled SVG charts, no chart library); CSV export (long format: experimentId, agentId, round, metric, value).
- **Discussion prompts** displayed with results: "Your judge measured X. Did the agent get better at *art* or better at *pleasing the judge*? How would you tell the difference?"

---

## 10. Student Notebook (dual reflection)

After each round and each crit session, the Notebook gently offers one prompt (skippable, never modal-blocking). Rotate from a bank of ~15, e.g.: "Your agent kept drawing the same spiral. What do *you* do when you're stuck?", "You deleted one of its lessons. How did you decide?", "Whose drawing is it when you edit your agent's work?" Free-text entries, timestamped, linked to the round/crit they followed. Export as Markdown.

---

## 11. Sharing without a server

- **Agent trading card:** JSON export of one agent (anatomy + lessons + journal + its 3 best works inc. thumbnails). Import merges with new ids. Pretty enough to print is a non-goal for v1.
- **Gallery export:** one self-contained static HTML file (inline images/styles, no JS required) of selected works — for class walls, email, school VLEs.
- **Full backup:** everything as one JSON.

---

## 12. Safety and tone (hard requirements)

- Every LLM call's composed prompt includes a fixed, visible preamble: audience is children; content must be age-appropriate; no violence, romance, scary or mature themes; poems and statements in simple warm language.
- **Plain-text output mandate:** the preamble forbids markdown in model replies (no asterisks, headings, bold, code spans; bullets only where a format explicitly asks for "- " lines). Belt-and-braces: a `stripMd()` sanitizer is applied to every parsed model output before storage/display, since stored text is re-fed into later prompts and leaked `**bold**` otherwise propagates.
- Critique kindness rules in every critic/judge call: be specific, lead with something that works, one wish for next time, never mock or compare people, talk about the work not the maker.
- No personal data: the app never asks for names/emails; agent names are fictional; warn (kid-readable) before any export that files may be shared.
- API keys (standalone): stored in localStorage with a plain warning ("only on a computer you trust"); never exported in backups or trading cards; masked in UI.

---

## 13. Runtime, providers, budgets

### 13.1 Two runtime modes, auto-detected
- **Artifact mode (keyless Claude):** when running inside a Claude artifact, call `https://api.anthropic.com/v1/messages` via fetch **without** an API key (the environment handles auth). Use model `"claude-sonnet-4-20250514"` for all roles in artifact mode, `max_tokens: 1000`. Vision: image content blocks with base64 PNG. Detect artifact mode by attempting a featherweight probe call on first use (or catching the standalone key-missing state); allow manual override in Settings.
- **Standalone mode (BYO key):** provider adapters for Anthropic, OpenAI, Google behind one interface:
  `llm.complete({ role, system, messages, images?, maxTokens }) → { text, usage? }`
  Adapters handle each provider's message/image formats and errors. CORS note: Anthropic supports browser calls with `anthropic-dangerous-direct-browser-access: true` header; verify current headers and the other providers' browser-CORS status against their docs at build time, and degrade gracefully (clear error + link to settings) if a provider blocks browser use.

### 13.2 Role → model mapping (standalone defaults; editable table in Settings)
- maker: cheap+fast (Anthropic: `claude-haiku-4-5-20251001`; OpenAI/Google: current small models)
- eyes: vision-capable mid (Anthropic: `claude-sonnet-4-6`)
- judge: same tier as eyes, fixed per experiment
- reflect: cheap (haiku tier)

Model strings drift; the builder must verify current model ids against https://docs.claude.com/en/docs_site_map.md (and the OpenAI/Google docs) at build time, keep them in one `MODEL_DEFAULTS` constant, and let users type arbitrary model ids in Settings. (FYI: `claude-fable-5` is now available on the Anthropic API if the owner wants a premium judge option.)

### 13.3 Resilience
Retry once on transient failure with small backoff; on final failure, show a kid-friendly card ("The art helper didn't answer. Want to try again?") and preserve all completed phases of the round.

### 13.4 Budgets
Settings caps: max rounds per session (default 10), max tokens per call (default 1000). A small running meter shows calls made this session and a rough cost estimate (per-provider rough table in one constant; label it "rough guess"). Science Corner shows total estimated calls (2 agents × N rounds × phases) *before* running.

---

## 14. Engineering constraints (non-negotiable)

- **One file:** `atelier.html`. Vanilla JS + inline CSS. No frameworks, no build step, no CDN dependencies. Must work from `file://` and from a static server. Target < 500 KB.
- Organize with loud comment banners: `/* ===== SECTION: TURTLE ENGINE ===== */` etc. Suggested sections: CONSTANTS & MODEL_DEFAULTS, STATE & PERSISTENCE, LLM ADAPTERS, PROMPT COMPOSITION, TURTLE ENGINE & SANDBOX, POEM RENDERER, ROUND ENGINE, CRIT ROOM, SCIENCE CORNER, METRICS (aHash, Jaccard, diff), UI COMPONENTS, SCREENS, COPY & TEMPLATES (all child-facing strings and starter minds live here for easy editing), BIG IDEAS, BOOT.
- The sandbox iframe is created via `srcdoc` from a string constant inside the same file (keeps single-file purity).
- Expose a tiny test hook: `window.__atelier = { state, runPhase, renderTurtle(code) }` for the Playwright harness.
- Deterministic test path: a `mock` provider (Settings-selectable, also `?mock=1`) returning canned maker/eyes/reflect outputs, so the full loop can be exercised and screenshotted with zero API calls.

---

## 15. Milestones

**M0 — Skeleton + turtle engine.** Shell UI with nav; turtle sandbox runs hand-written code; animated replay; snapshot; payload editor with re-render. *Accept:* harness screenshot of a known spiral matches reference; error path renders a friendly card.

**M1 — Core loop, one turtle agent, mock + real providers.** Agent creation (templates), mind editor, full 7-phase round, journal, lessons with distillation, localStorage persistence. *Accept:* 5 mock-mode rounds run end-to-end deterministically; 5 real rounds show visible change; refresh mid-round loses nothing.

**M2 — Poets, Gallery, Crit Room, student critique, human editing diffs.** *Accept:* cross-media crit session of 3 agents completes; humanEdited diff note demonstrably reaches the next Make call (visible in peek-under-the-hood).

**M3 — Notebook, trading cards, gallery HTML export, budgets/meter, settings polish, Big Idea bubbles, full copy pass to age-9 reading level.** *Accept:* exported gallery HTML opens standalone; import of a trading card round-trips.

**M4 — Science Corner.** Wizard, paired runs, metrics, SVG charts, CSV export, discussion prompts. *Accept:* an Eyes-on vs Eyes-off experiment over 6 mock rounds produces a correct CSV and sensible charts; aHash novelty verified against two known images.

Riskiest-first order is deliberate: the loop (M0–M1) is the heart; everything else decorates it.

## 16. Out of scope for v1 (note for the future)

Multiplayer/shared walls, more media (music, vector animation), agents teaching agents, audio read-aloud, printing trading cards, teacher dashboards, i18n.
