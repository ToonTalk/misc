# Add a voice guide to this app

Attached: (1) a single-file HTML app; (2) `vg-core.js`, the app-agnostic voice-guide core;
(3) optionally `first-day-adapter.js`, the reference adapter, worth skimming as a worked
example. The port-the-reference era is over: **do not re-implement the panel, speech,
takeover, confirm-wrapper, or Q&A machinery — write an adapter and hand it to
`VoiceGuide.create(adapter)`.**

Task: give the app a self-contained "guide" layer — a spoken guided tour plus voice/typed
Q&A — as an appended layer: no edits above the splice point. The build splices
`<script>vg-core.js</script><script>your-adapter.js</script>` before `</body>`; the shipped
app stays ONE html file (the core is authoring-time reuse, not a runtime dependency). Drive
the app only through its real controls and existing globals (window functions are patchable
from below the splice; that counts as "real controls one level down" when the click dance is
fragile — say so in the report).

## The split

**Core owns (don't rebuild, don't fork):** panel markup + generated CSS (docked side panel,
bottom-dock on narrow, edge tab, transcript log, status line, typed ask box), chunked TTS
with watchdog + read-along fallback, spotlight with respot-after-render, the tour runner and
its ONE generation counter, pause/resume/skip/end, trusted-event takeover, the
`window.confirm` wrapper with all three fallback tiers, mic-by-policy detection + explainer,
speech recognition, user-prompt assembly (history + STATUS RIGHT NOW placement), DO
extraction and dispatch order (validate → ratify → exec → respot → re-baseline), the
keyed/keyless/no-AI LLM chain, `window.__guide` assembly, and open-state persistence.

**Adapter owns (everything that names an app thing):** tour stops, provenance snapshot +
diff wording, the system prompt (app grounding + voice override), the DO verb table, SHOW
targets, confirm rules, reflow CSS for the app's breakpoints, LLM plumbing hooks, strings
(greeting, mascot, hide toast, key hint), the `__guide.app` test surface, and an `init(api)`
for app-specific patches (keyless gate wraps, below-the-fold watchers, settings-modal notes).

## The adapter interface

`VoiceGuide` is the core's only global: `{version, fragments, create(adapter)}`. No side
effects until `create()`. **`create(adapter)` returns the api handle** — steps are built
before `create()` runs, so use the stash pattern:

```js
let api;                       // step/verb closures resolve this at call time
const STEPS = [...uses api.wait, api.demoMs, api.respot, api.canListen...];
api = VoiceGuide.create({ tour:{steps:STEPS}, ... });
```

```js
VoiceGuide.create({
  id: 'my-app',                // storage key prefix: '<id>-guide-panel'
  ui: {
    title, ariaLabel, mascot, thinkFace, tabLabel, tabTitle, askPlaceholder,
    greeting(canListen),       // -> string; logged at create
    hideToast,                 // toast on hide, pointing at the edge tab
    doneStatus,                // status line when the tour completes
    notify(text),              // the app's toast, or your own
    modal: {backdrop, modal, row, yes, no}   // confirm-dialog class names; defaults
  },                           //   match common single-file-app modals; core also ships
                               //   zero-specificity :where() fallback CSS for the dialog
  layout: {
    panelWidth: 300, panelMargin: 302, narrowMax: 700,
    appBreakpoint: 1180,       // the app's own stacking breakpoint
    reflowCSS: {
      mirrored: '...css...',   // the app's stacked layout, under body.vg-open; core wraps
                               //   it in @media (max-width: appBreakpoint + panelMargin)
      bands: [{max: 1560, css: '...'}]   // grid-minimum softening just above the mirror;
    }                          //   emitted BEFORE the mirror so the mirror wins below it
  },
  takeover: {
    events: ['pointerdown','keydown'],  // which trusted events count as user takeover;
                                        //   keyboard-driven apps should drop 'keydown'
    ignore(e)                  // optional extra escape hatch -> true to let it through
  },
  tour: { steps: [...] },      // step: {name, spot, text|text(), prep()?, action(gen)?,
                               //   during?, skipIf?} — semantics unchanged from v2
  provenance: {
    snapshot(),                // app-state snapshot for pause/resume
    diffRemark(oldSnap)        // one spoken line of what the PLAYER changed, or '' —
  },                           //   side-effect suppression and wording live here
  prompts: {
    system(ctx),               // ctx = {tourLive, stopName}; return grounding + override
    status()                   // fresh state serialization for the STATUS RIGHT NOW block
  },
  llm: {
    hasKey(),                  // truthy -> keyedCall handles it
    keyedCall(sys, user),      // the app's own plumbing, provider/model as configured
    normalizeReply(text),      // app's id->name cleaner; core runs it AFTER DO extraction
    extractError(data, res),   // optional; default reads data.error.message
    keylessModels: [...],      // optional; default ['claude-sonnet-5','claude-sonnet-4-6']
    noAI: {spot, say}          // where to point and what to say when no AI path exists
  },
  verbs: {                     // the DO table; core uppercases the verb and splits args
    VERB: {
      gated: true?,            // story-moving verbs: ratified through the in-page dialog
      validate(parts, api)?,   // -> falsy = silent no-op (BEFORE any dialog); a truthy
                               //   return is passed on as ctx (parse once, use twice)
      ratifyText(parts, ctx, api)?,  // required when gated: 'The guide wants to ... OK?'
      exec(parts, api, ctx)    // drive the app's real controls; re-check app gating here
    }
  },
  confirmRules: [              // per-message dressing for the confirm wrapper
    {match: /regex on the confirm message/, hint, extraLabel?, onExtra(api)?}
  ],
  strings: {
    micKeyHint                 // tail of the mic explainer's key sentence, e.g.
  },                           //   ', via the gold Live AI setup button.' (default '.')
  testHook: { app() },         // -> the app's top-level let/const bindings for the suite
  init(api)                    // last thing create() does; app-specific patches go here
});
```

The api handle (returned, passed to `init`, and third-hand to verb `exec`s):
`wait(ms, gen)`, `demoMs(ms)`, `clickSel(sel)`, `spot(selOrFn)`, `respot()`, `unspot()`,
`speak(text, gen, who)`, `logAdd(text, who)`, `status(text)`, `ratify(msg) -> Promise<bool>`,
`showConfirm(msg, onYes, opts)`, `notify(text)`, `keylessCall(sys, user)`, and read-only
`inClaude`, `micPolicyBlocked`, `canListen`.

**`VoiceGuide.fragments`** holds the canonical prompt-rule sentences — `voiceRules`,
`statusRule`, `selfKnowledge`, `doLineMeta`, `ratifyNotice`, and parameterized
`consentScope({pointExample, escalations, safeVerb})` and
`pointNotDescribe({pointVerbs})`. These are load-bearing safety policy: **compose your
override from them instead of copying the sentences**, so the policy has one home. Where an
app genuinely needs different wording, write it — but say so in the report.

## Invariants (the *why*; core enforces most, the rest are adapter duties)

1. **Panel, not overlay — and reflow means the app's breakpoints too.** [core mechanism,
   adapter numbers] Body margin alone is NOT enough: the app's grid minimums overflow
   horizontally *underneath* the fixed panel. Find the app's stacking breakpoint and grid
   minimums; hand core `appBreakpoint` + `reflowCSS`. Core does the rest, including
   bottom-dock on narrow screens and the labeled edge tab.
2. **Transcript, not captions.** [core]
3. **One generation counter cancels everything.** [core] Step `action(gen)`s must pass the
   gen to `api.wait` so they cancel too.
4. **User takeover via `isTrusted`.** [core mechanism, adapter event list] Synthetic clicks
   are untrusted, so the guide never pauses itself. Choose `takeover.events` per app: a
   keyboard-shortcut-heavy app wants pointerdown only.
5. **Provenance-correct resume.** [core timing, adapter content] Core snapshots on pause and
   re-baselines after any guide-driven change; your `diffRemark` owns wording, side-effect
   suppression (report the cause, not its forced effects), minor-facets-only-when-nothing-
   bigger, and the two-fact cap.
6. **Mic by policy, not by error.** [core] Your only seam is `strings.micKeyHint`.
7. **Sandboxed modals are silently swallowed.** [core] Artifact iframes lack `allow-modals`;
   core wraps `window.confirm` (remember-and-re-trigger, native-dialog timing heuristic,
   press-again toast). You supply `confirmRules` — destructive confirms should offer the
   app's export as an escape hatch. Caveat to verify per app: handler side effects before
   the confirm call repeat on re-trigger.
8. **TTS realities.** [core] Chunking, watchdog, `resume()` before `speak()`, read-along
   fallback with `setWordMs(0)` for tests.
9. **Below-the-fold reveals must announce themselves.** [adapter, in `init`] Watch the
   transition (capture records the before-state, bubble runs after the app's handler), then
   `scrollIntoView` + toast. Core's spotlight already scrolls when pointing.
10. **The model guesses every binding you leave implicit — so leave none.** [adapter, in
    `prompts.system`] Fresh STATUS block placement and the status-outranks-history rule are
    core+fragments; still on you: bind every DO id to its visible name in one table and
    require id-prose agreement; enumerate how interactions actually work ("no drag and drop
    anywhere; the Attach button is the whole story"); compose `pointNotDescribe` and
    `consentScope` with your app's verbs and nouns.
11. **Policy the model must not break goes into mechanism, not prose.** [core order, adapter
    table] Story-moving verbs get `gated: true` — prompt-gated AND player-ratified; core
    validates before asking so nobody ratifies an impossible act; pointing verbs stay
    frictionless. Tell the model the app will ask (`fragments.ratifyNotice`).
12. **Tests or it didn't happen.** [adapter + suite] Core ships `__guide` (do / snap / diff /
    pauseCore / ask / system / layout, plus read-only state); you ship `testHook.app` —
    top-level `let`/`const` are global-lexical, not window properties, so the suite can't
    reach them otherwise. Write/port the jsdom smoke suite: loads clean; tour start / pause /
    user-change → resume-remark *wording* incl. side-effect suppression; skip; end; typed-ask
    with stubbed fetch (model chain, DO stripping, re-baselining, STATUS position);
    keyed-path routing; DO gating + ratification; the confirm wrapper's three tiers (jsdom's
    instant-return confirm exercises the swallowed case for free); simulated-artifact run
    (stub `permissionsPolicy` in `beforeParse`) asserting the mic explainer. jsdom can't
    forge `isTrusted`: test takeover by its inverse — synthetic clicks must NOT pause. Assert
    the generated stylesheet against `__guide.layout` (config-derived), not source greps.
    `node --check` every script block. Cross-check every id, selector, and app global the
    adapter references. Spotlight selectors verified tight. Run the suite twice; quote the
    PASS count in the report — it doubles as a build fingerprint, and a different count on
    the user's machine means a stale file was served.

## Defaults (override where the app argues otherwise)

- Panel ~300px right side; core matches the app's palette via `--panel/--ink/--accent/
  --muted/--line/--gold` CSS variables with dark-theme fallbacks — if the app doesn't define
  those variables, restyle via your own CSS or accept the fallbacks (note it in the report).
- Tour: 10–15 stops; `text` may be a function of live state (name what's actually present,
  adapt if the user already did the thing); actions idempotent and re-run-safe; `during:true`
  when motion should match words; the tour itself never presses story-moving buttons — it
  points and says whose move it is.
- Q&A: reuse the app's existing LLM plumbing and grounding prompt — never add a parallel AI
  path (an unknown-role fallback in the app's own prompt builder is often a free ride; check
  it emits no `undefined`). Mirror the questioner's register.
- Keyless: a configured key always wins, on the user's own provider and model. If the app
  gates its own AI features on a key, wrap the gate from `init` (sentinel key the wrapped
  `callLLM` recognizes; restore in `finally`) so the whole app works keyless in artifacts,
  and say so in the app's AI settings.
- Tour ends by inviting exploration; questions work anytime.

## Fill in per app

- Audience / tone: ___
- Tour stops: propose them from the app's actual UI; if more than one plausible tour spine,
  show me the proposed stop list before writing narration.
- Existing LLM plumbing? ___ (if none, wire `llm.keyedCall` to nothing and rely on the
  keyless path + `noAI` steer, or add the usual multi-provider key UI)
- Does the app use `confirm()`/`alert()` anywhere? (invariant 7's confirmRules apply) ___
- App's stacking breakpoint and grid minimums to mirror (invariant 1): ___
- Takeover events for this app (invariant 4 — keyboard-heavy apps: pointerdown only): ___

Finish by reporting: what the tests verify vs. what needs a live eyeball (real TTS,
recognition, LLM round-trips, and layout reflow at real window sizes can't run headless),
the PASS-count fingerprint and built byte count, any fragments you did NOT compose from
`VoiceGuide.fragments` and why, and any judgment calls you made.
