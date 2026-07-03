# Add a voice guide to this app

Attached: (1) a single-file HTML app; (2) `in-between-voice-demo.html`, a working reference
implementation of this pattern. Port its architecture — don't reinvent it.

Task: append a self-contained "guide" layer — a spoken guided tour plus voice/typed Q&A — to
the app. Append-only: no edits above the splice point. Drive the app only through its real
controls and existing globals.

## Invariants (learned the hard way — don't relax these)

1. **Panel, not overlay.** Docked side panel; while open the app reflows around it (body
   margin), so occlusion is impossible by construction rather than avoided by dodging.
   Anchor `top:0; bottom:0`; no vh units — artifact iframes lie about the visible viewport.
   Collapsible to an edge tab (which pulses while the guide speaks); persist open state.
   On narrow screens an overlay is acceptable *because* it's hideable.
2. **Transcript, not captions.** The full text of each narration and answer lands at once as
   a block in a scrolling log (`flex:1; min-height:0; overflow-y:auto`) — reviewable history,
   and nothing can outgrow its container. Transients (paused / listening / thinking) go to a
   separate one-line status area, never the log.
3. **One generation counter cancels everything.** Every speech chunk, animation frame loop,
   timed wait, and pending LLM reply checks it; pause, skip, end, and a new question just
   bump it. No other cancellation mechanism.
4. **User takeover via `isTrusted`.** Any trusted pointerdown/keydown outside the panel while
   narrating auto-pauses the tour. The guide drives the app with synthetic `.click()` on the
   app's real buttons — synthetic events are untrusted, so the guide never pauses itself.
5. **Provenance-correct resume.** Snapshot app state on pause; on resume, speak a one-line
   diff of what the *user* changed. Re-baseline the snapshot after any guide-driven change
   (tour action or Q&A-driven action), so the guide never attributes its own driving to the
   user. Never report a state facet that is a forced side effect of another reported change
   (e.g. a dimension switch that swaps in its own programs: report the switch, not the swap).
6. **Mic by policy, not by error.** Detect a blocked microphone at load with
   `document.permissionsPolicy.allowsFeature('microphone')` (fall back to `featurePolicy`).
   If blocked — the Claude-artifact sandbox case — dim the mic button immediately; on press,
   explain that no permission prompt can ever appear here, steer to the permanent typed-input
   box at the panel's foot, and point to running the standalone file in a normal browser tab
   with the user's own API key. Keep this distinct from a runtime user denial
   (`not-allowed`), which gets address-bar advice instead.
7. **TTS realities.** Sentence-chunk every utterance (Chrome kills long ones ~15s); add a
   watchdog interval because `onend` is sometimes swallowed after `cancel()`; call
   `speechSynthesis.resume()` defensively before `speak()`; when TTS is absent, fall back to
   read-along timing (~300 ms/word) so the tour still works silently.
8. **Tests or it didn't happen.** Expose a `window.__guide` hook (do / snap / diff /
   pauseCore, plus read-only state) so internals are testable. Ship a jsdom smoke suite:
   loads clean, start, pause, user-change → resume-remark *wording*, skip, end, typed-ask
   path, and a simulated-artifact run (stub `permissionsPolicy` in `beforeParse`) asserting
   the mic explainer. `node --check` every script block. Cross-check that every id, selector,
   and app global the layer references actually exists. Spotlight selectors must be verified
   tight — they glow exactly the intended element(s), nothing adjacent; support multi-element
   targets (a function returning elements beats a broad container class).

## Defaults (override where the app argues otherwise)

- Right-side panel ~300px, mascot header, matching the app's own palette and fonts. Controls:
  one main button cycling start/pause/resume/replay, mic, skip, end; Ask box always visible.
- Tour: 10–15 stops, each `{name, spot, text, action?, during?, skipIf?}`. `text` may be a
  function of live state (name the shapes actually loaded, adapt if the user already did the
  thing). Actions must be idempotent and re-run-safe — restarting an interrupted stop must
  not stomp user changes. `during:true` runs the action concurrently with narration so the
  motion matches the words.
- Q&A: reuse the app's existing LLM plumbing and grounding prompt if it has one — never add a
  parallel AI path. Append a voice override: plain speakable prose, no markdown or emoji,
  1–3 sentences; default register for the stated audience but mirror the questioner's
  register. Let the model drive the app through a one-line whitelist protocol
  (`DO: VERB args`) parsed and stripped before speaking; whitelist the verbs per app;
  DO-driven changes update provenance per invariant 5.
- Tour ends by inviting exploration; questions work anytime, tour running or not.

## Fill in per app

- Audience / tone: ___
- Tour stops: propose them from the app's actual UI; if the app supports more than one
  plausible tour spine, show me the proposed stop list before writing narration.
- Existing LLM plumbing? ___ (if none, add my usual keyless-Anthropic-in-artifact default
  with multi-provider key fallback)

Finish by reporting: what the tests verify vs. what needs a live eyeball (real TTS,
recognition, and LLM round-trips can't run headless), and any judgment calls you made.
