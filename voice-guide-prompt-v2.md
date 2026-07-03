# Add a voice guide to this app

Attached: (1) a single-file HTML app; (2) `in-between-voice-demo.html`, a working reference
implementation of this pattern. Port its architecture — don't reinvent it. (When a shared
`vg-core.js` exists, most of this document collapses into "write the adapter"; until then,
port.)

Task: append a self-contained "guide" layer — a spoken guided tour plus voice/typed Q&A — to
the app. Append-only: no edits above the splice point. Drive the app only through its real
controls and existing globals (window functions are patchable from below the splice; that
counts as "real controls one level down" when the click dance is fragile — say so in the
report).

## Invariants (learned the hard way — don't relax these)

1. **Panel, not overlay — and reflow means the app's breakpoints too.** Docked side panel;
   while open the app reflows around it (body margin-right), so occlusion is impossible by
   construction. Body margin alone is NOT enough: the app's own responsive breakpoints don't
   know the panel exists, so its grid minimums overflow horizontally *underneath* the fixed
   panel. Mirror the app's stacking breakpoint at (breakpoint + panel width) under
   `body.vg-open`, and soften grid minimums in the band just above it. On narrow screens
   (artifact preview pane, phones) do NOT overlay — dock to the bottom instead
   (`margin-bottom`), so the guide never covers the app at any width. A player, especially a
   child, will not know to hide an overlay. Anchor `top:0; bottom:0`; no vh units — artifact
   iframes lie about the visible viewport. Collapsible to an edge tab that pulses while the
   guide speaks AND carries a visible text label ("Guide") — a bare mascot reads as
   decoration; on hide, toast where the tab is. Persist open state.
2. **Transcript, not captions.** The full text of each narration and answer lands at once as
   a block in a scrolling log (`flex:1; min-height:0; overflow-y:auto`) — reviewable history,
   and nothing can outgrow its container. Transients (paused / listening / thinking) go to a
   separate one-line status area, never the log.
3. **One generation counter cancels everything.** Every speech chunk, animation frame loop,
   timed wait, and pending LLM reply checks it; pause, skip, end, and a new question just
   bump it. No other cancellation mechanism.
4. **User takeover via `isTrusted`.** Any trusted pointerdown/keydown outside the panel (and
   outside the guide's own dialogs) while narrating auto-pauses the tour. The guide drives
   the app with synthetic `.click()` on the app's real buttons — synthetic events are
   untrusted, so the guide never pauses itself.
5. **Provenance-correct resume.** Snapshot app state on pause; on resume, speak a one-line
   diff of what the *user* changed. Re-baseline the snapshot after any guide-driven change
   (tour action or Q&A-driven action), so the guide never attributes its own driving to the
   user. Never report a state facet that is a forced side effect of another reported change
   (e.g. a dimension switch that swaps in its own programs: report the switch, not the swap).
   Minor facets (tab, selection) speak only when nothing bigger changed; cap the remark at
   two facts.
6. **Mic by policy, not by error.** Detect a blocked microphone at load with
   `document.permissionsPolicy.allowsFeature('microphone')` (fall back to `featurePolicy`).
   If blocked — the Claude-artifact sandbox case — dim the mic button immediately; on press,
   explain that no permission prompt can ever appear here, steer to the permanent typed-input
   box at the panel's foot, and point to running the standalone file in a normal browser tab
   with the user's own API key. Keep this distinct from a runtime user denial
   (`not-allowed`), which gets address-bar advice instead.
7. **Sandboxed modals are silently swallowed.** Artifact iframes lack `allow-modals`:
   `confirm()` returns false instantly, so every `if(confirm(...))` guard in the app aborts
   with no visible symptom (Reset buttons "do nothing"). `confirm` is synchronous and a nice
   dialog is not, so wrap `window.confirm` with the remember-and-re-trigger pattern: a
   capture-phase listener records the last pressed button (~3 s window, ignoring the guide's
   own UI); the wrapper answers false, shows an in-page dialog styled on the app's own
   modals, and on Yes pre-approves the message and synthetically re-clicks that button — the
   handler runs again and the wrapper answers true. Fallbacks when no trigger is known:
   native dialog (timing heuristic — a false returned in <150 ms was swallowed, a slower one
   is a human Cancel), then press-again-to-confirm via toast. Destructive confirms should
   offer the app's export as an escape hatch ("Export JSON first") if it has one. Caveat to
   verify per app: handler side effects before the confirm call repeat on re-trigger.
8. **TTS realities.** Sentence-chunk every utterance (Chrome kills long ones ~15s); add a
   watchdog interval because `onend` is sometimes swallowed after `cancel()`; call
   `speechSynthesis.resume()` defensively before `speak()`; when TTS is absent, fall back to
   read-along timing (~300 ms/word, settable to 0 for tests) so the tour still works
   silently.
9. **Below-the-fold reveals must announce themselves.** In stacked layouts, an action that
   reveals content off-screen (opening a work area, unlocking a panel) looks like it did
   nothing. Watch the transition (capture records the before-state, bubble runs after the
   app's handler), then `scrollIntoView` the revealed thing and toast where it appeared.
   The same applies to guide pointing: spotlighting scrolls to the target.
10. **The model guesses every binding you leave implicit — so leave none.** Each failure in
    the field so far was one of these; each fix is cheap:
    - *Live state loses to stale history.* Grounding in the system prompt is not enough: put
      a fresh `STATUS RIGHT NOW` block in the **user** prompt, after the flattened Q&A
      history and immediately before the question, with an explicit status-outranks-history
      rule ("never advise a step the status shows as done"). Recency bias then works for you.
    - *Ids must be bound to names in one table.* Anywhere the DO protocol takes an id, the
      prompt must enumerate `id (visible name)` pairs and require the id to match the thing
      named in prose. Models that only see ids in incidental structure will bind
      "Assistant game designer" to `artist`. Pointing at the wrong thing is worse than not
      pointing.
    - *Enumerate how interactions actually work* ("there is no drag and drop anywhere; the
      Attach to ⟨object⟩ button is the whole story") or the model confabulates plausible
      controls.
    - *Point, don't describe.* "Where is / I don't see / how do I get to" questions must
      ALWAYS end with a DO SHOW/TAB line — the page is usually taller than the window.
    - *Consent scope.* "Please do" authorizes only the exact action just offered; never
      escalate a jump-offer into a state-changing act; prose must name a state-changing act
      before doing it.
11. **Policy the model must not break goes into mechanism, not prose.** State-changing DO
    verbs (accepting briefs, attaching, opening gated areas) are two-tier: prompt-gated to
    explicit requests, AND player-ratified through the in-page dialog ("The guide wants to
    attach X to Y for you. OK?"). The model proposes; the player countersigns. Validate
    (locked, invalid id) *before* asking, so nobody ratifies an impossible act. Pointing
    verbs stay frictionless. Tell the model the app will ask, so it says "asking" rather
    than claiming the deed is done.
12. **Tests or it didn't happen.** Expose a `window.__guide` hook (do / snap / diff /
    pauseCore / ask / system, plus read-only state) so internals are testable. Top-level
    `let`/`const` in a classic script are global-lexical, not window properties — surface
    them through an `__guide.app` getter or the suite can't reach them. Ship a jsdom smoke
    suite: loads clean, start, pause, user-change → resume-remark *wording* including
    side-effect suppression, skip, end, typed-ask path with stubbed fetch (assert model
    chain, DO stripping, re-baselining, status block position), keyed-path routing, DO
    gating and ratification flows, the confirm wrapper (all three fallback paths — jsdom's
    instant-return confirm exercises the swallowed case for free), and a simulated-artifact
    run (stub `permissionsPolicy` in `beforeParse`) asserting the mic explainer. jsdom can't
    forge `isTrusted`, so test takeover by its inverse: synthetic clicks must NOT pause.
    `node --check` every script block. Cross-check that every id, selector, and app global
    the layer references actually exists. Spotlight selectors must be verified tight — they
    glow exactly the intended element(s); a function returning elements beats a broad
    container class. Run the suite twice. The final PASS count doubles as a build
    fingerprint: quote it in the report, and when the user's run shows a different count,
    the delivery channel served a stale file.

## Defaults (override where the app argues otherwise)

- Right-side panel ~300px, mascot header, matching the app's own palette and fonts. Controls:
  one main button cycling start/pause/resume/replay, mic, skip, end; Ask box always visible.
- Tour: 10–15 stops, each `{name, spot, text, prep?, action?, during?, skipIf?}`. `prep` runs
  before the spotlight (tab switches via real buttons). `text` may be a function of live
  state (name the things actually present, adapt if the user already did the thing). Actions
  must be idempotent and re-run-safe — restarting an interrupted stop must not stomp user
  changes. `during:true` runs the action concurrently with narration so the motion matches
  the words. The tour itself never presses story-moving buttons; it points at them and says
  whose move it is.
- Q&A: reuse the app's existing LLM plumbing and grounding prompt if it has one — never add a
  parallel AI path (an unknown-role fallback in the app's own prompt builder is often a free
  ride; check it emits no `undefined`). Append a voice override: plain speakable prose, no
  markdown or emoji, 1–3 sentences; default register for the stated audience but mirror the
  questioner's register. Let the model drive the app through a one-line whitelist protocol
  (`DO: VERB args`) parsed and stripped before speaking; whitelist the verbs per app. If the
  app has a reply normalizer that rewrites ids to names, run it AFTER DO extraction or it
  corrupts the DO arguments. Give the model self-knowledge: it lives in a docked panel, the
  app reflows so it never covers it, and the hide affordance exists.
- Keyless: `VG_KEYLESS_MODELS = [newest, known-good]` tried in order — the artifact proxy's
  allow-list lags launches; keep it a one-line constant. A configured key always wins, on the
  user's own provider and model. If the app gates its own AI features on a key, wrap the gate
  from below the splice (sentinel key the wrapped `callLLM` recognizes; restore in
  `finally`) so the whole app works keyless in artifacts, and say so in the app's AI
  settings.
- Tour ends by inviting exploration; questions work anytime, tour running or not.

## Fill in per app

- Audience / tone: ___
- Tour stops: propose them from the app's actual UI; if the app supports more than one
  plausible tour spine, show me the proposed stop list before writing narration.
- Existing LLM plumbing? ___ (if none, add my usual keyless-Anthropic-in-artifact default
  with multi-provider key fallback)
- Does the app use `confirm()`/`alert()` anywhere? (invariant 7 applies) ___
- App's responsive breakpoints to mirror (invariant 1): ___

Finish by reporting: what the tests verify vs. what needs a live eyeball (real TTS,
recognition, LLM round-trips, and layout reflow at real window sizes can't run headless),
the PASS-count fingerprint, and any judgment calls you made.
