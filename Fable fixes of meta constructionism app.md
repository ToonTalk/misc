# Atelier — review punch list (line numbers refer to the reviewed atelier.html, 2,554 lines)

## A. Bugs to fix before calling it final

### A1. Google model defaults are dead models (breaks the whole Google path)
`MODEL_DEFAULTS.google` (line 238) uses `gemini-1.5-flash` / `gemini-1.5-pro`. All Gemini 1.0 and 1.5
models are shut down and return 404 (confirmed against ai.google.dev and Firebase docs, June 2026).
Every Google-key user gets "could not find that model" on their first round.
**Fix:** replace with current GA ids, e.g. maker/reflect: `gemini-2.5-flash` (or `-lite`),
eyes/judge: `gemini-2.5-pro`. (`gemini-3.5-flash` is the newest GA option if preferred.)
Re-verify ids at fix time per CLAUDE.md.

### A2. "Peek under the hood" shows a reconstructed prompt, not the one actually sent
In runRound the hood recomputes the prompt AFTER state has changed:
- Make (line 1267): `hoodView("Make", makerPrompt(...))` runs after `state.works.push(work)` and after
  marking critiques `readByAgent` — the recomputed prompt shows the NEW work as "your previous work"
  and omits the critiques that were actually sent.
- Reflect (line 1326): recomputed after `journal.push` — shows this round's entry as "your last journal entry."
- Distill (line 1344): recomputed after lessons were replaced — shows the new lessons as "current lessons."
(Look at line 1305 happens to be safe, but fix it the same way for consistency.)
This breaks the glass-box promise the hood exists for.
**Fix:** capture each prompt in a const before the llm.complete call and pass that same string to both
the call and hoodView. Four one-line changes.

### A3. Experiment failure handling: "Try again" duplicates everything
In openExperimentWizard (lines 2220–2237), clones + experiment are created inside go.onclick, and the
catch re-enables the same button — pressing "Try again" creates a SECOND baseline/variant pair and a
second experiment; the failed partial experiment and its clones stay in state with no resume.
**Fix:** split creation from running. On failure keep the created exp and offer "Resume" that calls a
runExperiment variant continuing from `exp.results.length` (don't reset `exp.results=[]` when resuming);
or delete the partial exp + clones before retrying. Also: runExperiment should catch per-round errors
and surface them in the experiment card rather than letting the wizard toast be the only trace.

### A4. XSS sink in the Show & Tell picker
Line 2117: `el("span","", a.look.emoji+" "+a.name+(last? " — latest: "+last.title : ...))` —
`name` and `title` are interpolated into innerHTML unescaped. Imported trading cards are
deliberately kid-to-kid shareable, and sanitizeAgent/sanitizeWork length-cap but do NOT strip HTML,
so a crafted card (name = `<img src=x onerror=...>`) executes on this screen.
**Fix:** wrap in esc(): `esc(a.name)`, `esc(last.title)`. Grep for any other unescaped
name/title interpolations in HTML (the rest I checked are escaped).

### A5. Artifact mode: storage failure shows the wrong message
localStorage is unavailable inside Claude artifacts (sandboxed); save()'s catch (line 449) then toasts
"This browser's storage is full" — misleading, and it implies saving normally works.
**Fix:** probe storage once at boot (try setItem/removeItem). If unavailable: suppress the per-save
toast and show a small persistent banner: "Running inside Claude: your studio is not saved between
visits here — use Settings → Export to keep a backup." Also hide/adapt "Start over" (which relies on
localStorage.removeItem + reload). Test inside an actual artifact.

## B. Smaller fixes

1. **Sandbox not recreated after timeout** (lines 976–982): a hung run leaves the iframe wedged but
   reused for the next run. On timeout, remove the iframe and null `_sandbox`/`_sandboxReady` so the
   next run gets a fresh one.
2. **Judge model isn't actually fixed per experiment**: roleModel("judge") reads live settings at every
   call, so editing the judge model mid-run changes the judge (spec says fixed for the whole
   experiment). Snapshot `{provider, model}` into `exp.judgeSpec` at creation and use it in
   runExperiment; show it in experimentView.
3. **Settings copy contradicts hood behavior** (line 2285 says Advanced opens hood panels by default;
   hoodView line 1109 says always collapsed). Pick one — suggest: add `open` attribute when
   `state.settings.advancedMode`, matching the copy.
4. **Experiment wizard's base-mind select includes experiment clones** (line 2189 uses state.agents
   unfiltered) — leads to "X (baseline) (variant)" chains. Filter `!a.experimentId` like the Studio does.
5. **Google copy slightly wrong** (lines 641, 2315): the June 19, 2026 change rejects ALL unrestricted
   standard keys (existing ones included), not just "keys made after" that date; new AI Studio keys are
   already restricted auth keys by default. Reword: "From 19 June 2026 Google rejects unrestricted
   keys — in AI Studio, add the 'Restrict to Gemini API' setting to your key."
6. **OpenAI empty-reply risk**: reasoning models can spend the whole `max_completion_tokens` budget
   (1000) on reasoning and return empty content, which surfaces as "empty reply." For OpenAI calls,
   consider raising the effective cap (e.g. `Math.max(max, 2000)`) and/or mentioning the model's
   reasoning budget in the empty-reply error text.
7. **Mock judge can't separate baseline from variant** (line 696: score depends only on round) — mock
   experiments draw identical lines, which undercuts the demo. Hash the agent id into a small offset so
   the two arms visibly differ in mock mode.
8. **Old Show & Tell transcripts after "fresh set of rounds"**: critTurnEl renders empty quotes for
   turns whose workId was deleted (line 2054–2056). Fall back to "an earlier work" when the work is gone.

## C. Worth considering (not bugs)

- **Resume + replicate for experiments**: a "Run it again" button on a finished experiment (new clones,
  same spec) directly serves discussion prompt #3 ("would you get the same chart?") — variance made visible.
- **Export an experiment as a single HTML report** (charts inlined as SVG, strips inline) to match the
  rounds/gallery exporters.
- **system param in keyless artifact mode**: PREAMBLE is sent via `body.system`; verify inside a real
  artifact that the keyless proxy forwards `system` (if not, fold PREAMBLE into userText) — silent loss
  of the safety preamble would be bad.
- **Auto-detect standalone on boot**: if `!inEmbeddedFrame` and no saved settings, default runtimeMode
  to "standalone" + mock on, so a double-clicked file works instantly instead of failing its first call.
