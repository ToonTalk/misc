# Thought Bubble guide — session report (adapter #3)

## Fingerprints (sha256, first 16 hex)

| artifact | sha256 | bytes |
|---|---|---|
| jlens-explorer.html (pristine upload, input) | `ebd572b4f58d87a0` | 94,627 |
| jlens-prefixed.html (pre-fixes, rev 9) | `078722c271d40b3d` | 101552 |
| **vg-core.js v1.2 (CHANGED this session, twice)** | `f4be563195942054` | 41,158 |
| vg-core-v1.2.diff (v1 → v1.2, for Claude Code parity) | — | — |
| jlens-adapter.js (rev 9) | `829d4217da409590` | 49231 |
| **jlens-guided.html (deliverable, rev 9)** | `d92cc9f22bcca883` | 192077 |
| guides/thought-bubble-guide-kids.html (rev 8) | `6b345834fdb3e034` | — |
| guides/thought-bubble-guide-older-kids.html (rev 8) | `303828f944a72487` | — |
| guides/thought-bubble-guide-teachers.html (rev 9) | `5e240de2ccc2b82e` | — |
| guides/thought-bubble-making-of.html (rev 8) | `e8d5e5f128fa7b76` | — |
| patch-jlens-prefix.mjs (rev 9) | `7b83718317671860` | 20175 |
| build-jlens-guided.sh (rev 9) | `ab86c02445e39120` | — |
| smoke-jlens.mjs (rev 9) | `0d0b3dcd974b2bbe` | — |

**Suite: PASS 159 / FAIL 0, three consecutive runs** (exit 0 each; rev 1
105×3, rev 2 111×3, rev 3 124×3, rev 4 139×3, rev 5 149×3, rev 6–8 154×3). Build is
reproducible: patcher refuses any input but `ebd572b4…`; build script refuses
any prefixed app but `696f4b4c…` and any core but `281c49bb…`.

**Baseline note.** The kickoff says to verify the Phase 1.5 IndexedDB/pool
build "by checking the README fingerprint" — no README was uploaded to this
chat and the kickoff quotes no value. I verified by in-source markers instead
(IndexedDB cache store, multi-worker `Pool`, Phase-1.5 comments). If a README
fingerprint exists, quote it and I'll re-verify in one line.

**Container note.** The work container held leftover files from an earlier
session (an old jlens-adapter.js and prefix script, timestamps predating this
chat's uploads). Deleted; every deliverable above was built fresh from the
fingerprint-verified inputs. No provenance contamination.

## Rev 9 — droppable .zip, fresh artifact build, OpenAI default

Hugging Face fetch confirmed working live — hosting question closed.

**Zip drop (app-side, patcher):** drop a .zip on the dotted box and the app
unpacks it itself — a minimal reader (central-directory scan; stored and
deflate entries via DecompressionStream) that ignores folder paths and
__MACOSX junk, feeds each of the four expected files through the normal
arrival path, and fails softly on anything unreadable. The dropzone label
now says "— or a .zip of them"; the artifact empty-cache hint mentions the
starter .zip. Suite builds a real five-entry zip (nested folders, a stored
entry, macOS junk, an ignorable readme) and drives it through the app's
strict acked delivery chain (model → tokenizer → lens, one worker ack at a
time — a real app behavior the first version of the test didn't respect).

**Fresh artifact:** jlens-guided.html rev 9 is the file to publish as the
new artifact. Heads-up for the URL swap afterward: the OLD artifact URL
appears in **five places across the four guide pages** (the header nav on
all four, plus the teachers guide's two-ways bullet). One-liner once you
have the new id:
`sed -i 's|a7f0ab2b-c7d8-464d-b9d5-69c6461d3c6c|NEW-ID|g' guides/*.html`
— or send me the id and I'll ship the guides re-fingerprinted.

**Teachers guide:** both zip sentences updated per your spec (the Setup
fetch-blocked sentence and the artifact bullet now point at the starter
.zip, noting the app unpacks it itself).

**OpenAI default:** `gpt-5.4-mini` (adapter PROVIDERS table; the key
dialog prefills it).

**Rev 9 live-eyeball:** one real starter-.zip drop in a browser (the suite's
zips are synthetic; a Finder- or Explorer-made zip exercises data
descriptors and directory entries my reader deliberately routes around —
central-directory sizes make that safe, but one live drop confirms it).

## Rev 8 — both app links on every page; artifact explained

Guides-only rev; app, adapter, core, and suite untouched (guided build stays
`a6a885bb8761ee61`, PASS 154×3 from rev 7).

Every guide and the making-of page now opens with both ways in: the hosted
version (toontalk.github.io/jlens-tinystories) and the Claude artifact
(claude.ai/public/artifacts/a7f0ab…). The teachers guide gained a "Two ways
to run it" section: hosted = fetch button does everything, Maggie's Q&A
needs an adult-configured key; artifact = **no API key needed for Maggie
for anyone with a Claude account**, but no auto-fetch — download the model
(Hugging Face link) and drop it, or drop the files from the zip starter.
The Setup paragraph now covers the artifact's drop path explicitly.

**Flag — the zip starter:** the guide mentions it per your spec, but the
app's drop handler currently accepts only the four named files; a dropped
.zip is ignored with "not one of the four expected files". If the zip
starter should be droppable as-is, that's a small app feature (zip parsing
via DecompressionStream, ~60 lines, patcher-side) — say the word. If the
zip is meant to be unzipped by the user first, the guide wording still
holds; I can sharpen it to "unzip it and drop the four files" on your call.

## Rev 7 — model hosting: Google Drive → Hugging Face

Field result: Drive's download endpoint sends no
`Access-Control-Allow-Origin` header, so the browser blocked the fetch from
toontalk.github.io — the risk flagged in rev 6, confirmed. Switched to
**Hugging Face**: `huggingface.co/karpathy/tinyllamas/resolve/main/stories110M.bin`
— Karpathy's own llama2.c checkpoint repository, i.e. the canonical home of
this exact file. HF resolve URLs serve `Access-Control-Allow-Origin: *` by
design (transformers.js and the whole in-browser-ML ecosystem run on it), so
CORS should hold; still live-verify once. Changes: FETCH_URL, the artifact
empty-cache hint (now links Hugging Face), the error-page guard message made
host-neutral, and the teachers-guide setup section. Zero Drive references
remain in the build (suite-asserted).

Two follow-ups for you: (a) confirm your local stories110M.bin is
byte-identical to Karpathy's HF copy — your .jlens must match the checkpoint
it was trained against; if you ever touched the weights, we host YOUR copy
in an HF repo instead (one-line URL change). (b) Progress bar: if HF's CORS
doesn't expose Content-Length, the bar won't fill during the model fetch —
cosmetic, the download still works; tell me if you want an indeterminate
spinner fallback.

## Rev 6 — the four pages, Drive-hosted model, footer links

**No core change** (v1.2 stands). App changes are all patcher-side.

**The four pages** (the previous request — my reply was cut off before
delivery; they're in `guides/`, matching the footer's `../guides/` paths):
kids (8–11, mission structure, Maggie callouts), older kids (11–14, the two
lenses, swap mechanics incl. same-dice + self-gating, three runnable
experiments, glossary), teachers & parents (pedagogy, three classroom
activities with a deliberate null-result run, setup incl. the Drive
download, privacy: model fully local, Maggie's Q&A is the one optional
online feature), and the making-of (high-school/undergrad register: logit
lens → tuned lens → J-lens lineage; Anthropic background — features/Mapping
the Mind, Golden Gate Claude as the swap's big sibling, the 2025
poem-planning result as "getting ready to say" writ large; TinyStories +
Karpathy's stories110M; how the app is built). All single-file, app-palette
family, cross-linked; real citation URLs only, no invented quotes. The
making-of page is linked from the three guides but NOT from the app footer
(your footer spec listed the three guides + your post; say the word and it
joins).

**Drive-hosted model (standalone):** `fetchWithProgress` now routes
`stories110M.bin` to `drive.usercontent.google.com/download?id=…&confirm=t`
(the endpoint that skips Drive's virus-scan page); the three small files
stay relative. A content-type guard catches Drive returning HTML anyway and
tells the user to download + drop. **Unverifiable headless, must live-test:
Google's CORS behavior on that endpoint.** If the browser blocks it, the
guard's message and the drop path are the fallback — but tell me and I'll
switch strategy (e.g., a proper release-asset host).

**Artifact empty-cache hint:** on claudeusercontent hosts, if no model is
cached ~1.2 s after load, the files card shows "Get the model file from
Google Drive [link], then drop it on the dotted box." Hidden the moment a
model arrives by any path. **Flag — your spec names one Drive file, but an
artifact with an empty cache also lacks the three small files** (tokenizer,
lens, vocab.json; no relative fetch exists there). Options: make the Drive
link a four-file pack, add three more links, or embed the three small files
in the HTML (~a few MB?). Tell me which and it's a small patch.

**Footer note:** exactly per spec — the three guides at `../guides/` plus
your post's Google-Doc link.

**Confession for the doc bank:** rev 6's first build shipped two broken
`href="+"` anchors from a Python triple-quote mangle in my patcher edit —
the suite caught it (3 fails), fixed by inlining URLs. v4 lesson: patcher
edits that interpolate URLs should inline them; and every new DOM the
patcher injects needs a suite check on its *attributes*, not just presence.

**Rev 6 live-eyeball items:** the Drive fetch end-to-end from GitHub Pages
(CORS + the ~420 MB stream + progress bar without Content-Length); the four
pages' look on your machines and phones; whether the guides' register lands
for your audiences; making-of accuracy sweep (especially the Anthropic
sections — I kept claims to well-documented public results, but you know
this territory).

## Rev 5 — kid vocabulary + closing the readout-grounding gap

**No core change this rev** (vg-core.js stays v1.2 `f4be563195942054`).

**My rev-4 doctrine had a hole your transcript walked straight through:** it
told the model to "check the STATUS readout rows" — but statusText never
included the readout rows. Blind, the model delegated ("check the readout
panel to see if castle is showing up") and free-styled token arithmetic
("token 14, one step after your anchor… was already written" — backwards).
Three fixes:

1. **Readout in STATUS.** The rows exactly as rendered — top J-lens words
   per layer L4–L8, `[J-only]` marks, the model's-next-word row. Doctrine
   now adds: read them yourself, NEVER ask the visitor to go check the
   readout for you.
2. **Anchor arithmetic computed in code, not by the model.** STATUS states
   "Rewrites keep tokens 1 to N (the anchor) unchanged and regenerate
   everything after", and labels each occurrence of the take-out word
   "(at or before the anchor — stays written)" / "(after the anchor — that
   text is regenerated, not kept)". The model reads conclusions instead of
   doing index math.
3. **Causality without confabulation.** Rev 4 already surfaced identical
   rewrites; now STATUS also shows both continuations after the divergence
   point and a computed "the put-in word 'X' APPEARS / does NOT appear in
   the with-swap rewrite" flag. Doctrine: same dice means any difference IS
   the swap, but never invent a story about the direction of the change —
   check the landing flag; if the idea didn't land, say so and offer more
   strength in the green band, the full L4–L8 range, or a hotter anchor.
   Plus honest expectations: a small model's swap steers the drift of
   ideas, it cannot guarantee a word appears (your "nudged toward
   tower-like things" for a wave-and-danger ending was exactly the
   confabulation this targets).

**Kid-vocabulary sweep** (visitor-facing copy only; the model-facing
glossary keeps your canonical terms): loupe → magnifying glass everywhere a
child hears it; "disposed to say" spoken as "getting ready to say" (glossary
term retained in the prompt with an explicit speak-it-plainly register
note — flagging since the kickoff says encode the glossary exactly);
"intrigues you" → "looks interesting"; "small models oversteer" → "push too
hard and the story breaks"; strength tooltip simplified; the adoption
buttons now say what they do: "make 'no swap' the story" / "make 'with
swap' the story", hint "like a rewrite? … until you press one, your story
and anchor stay put". A suite check now runs the whole tour and asserts
nothing from the unfamiliar-word list is ever spoken.

**Rev 5 live-eyeball / judgment items:** whether STATUS is now too long
(readout rows + swap outcome add ~400 chars — watch answer quality; easy to
trim rows to L6–L8 if the model rambles); the glossary-verbatim-vs-register
tension above; and a live replay of the tower conversation — the guide
should now suggest take-out words *from* the readout it can see, and answer
"why didn't it work" with the landing flag rather than invented arithmetic.

## Rev 4 — voice, de-numbering, swap adoption, swap coaching

**⚠ vg-core.js CHANGED again: v1.1 → v1.2 `f4be563195942054`.** The attached
vg-core-v1.2.diff covers the full v1 → v1.2 delta for Claude Code. Refresh
the project-knowledge copy today (once, with v1.2). The v1.2 addition is one
seam: `speech: {prefer(voices), rate, pitch}` — adapter-owned persona voice.
Core tries `speech.prefer` before its natural/neural ranking and applies
rate/pitch per utterance. Hook: `__guide.voice`.

**Maggie's voice (adapter):** prefers a female English voice — voice APIs
carry no gender field, so it matches well-known female voice names
(Samantha, Zira, Aria, Jenny, Salli, Joanna, …), premium/neural variants
first — then pitch 1.3 and rate 1.06 for the bird-like chirp. Tunables;
tell me if she sounds like a chipmunk or a crow and I'll adjust. If the
platform has no recognizably female voice, core's old ranking applies.

**De-numbering (patcher):** panel h2s lose their "N ·" prefixes (your point:
with the panel open or a narrow window, visual order is 2,3,5,4 — numbers
mislead). All copy now names panels: the heat-strip hint drops "on the
right", the readout placeholder drops "on the left", the system prompt
enumerates panels by NAME with an explicit "deliberately not numbered"
instruction plus the honest layout note (readout beside the story on a wide
window, below on a narrow one), the tour's story/swap stops likewise.

**Swap adoption (app-side, your spec):** a finished swap no longer replaces
the story silently — that silent replace also silently reset the anchor,
which produced the guide's confusing "no starting point" line one turn after
an anchor plainly existed. Now the story AND anchor stay put; two
"study under the loupe" buttons under the panes load either rewrite into
the lens only when the player chooses (that load, like any new story, resets
the selection — the guide knows this). I chose per-pane buttons over a
blocking dialog: non-modal, artifact-safe, and it makes repeated swaps from
the same anchor natural. Veto if you wanted a dialog.

**Swap coaching (adapter):** two fixes to the failure you transcribed.
First, *grounding*: STATUS now reports the swap outcome — divergence point
and the with-swap continuation, an explicit "the two rewrites are IDENTICAL
— the edit found nothing to push on at that anchor" line for do-nothing
swaps, and where the take-out word sits relative to the anchor ("all at or
before the anchor, so it stays written in every rewrite"). The model
couldn't coach what it couldn't see. Second, *doctrine* in the system
prompt: anchor first and always name the exact word to click; the take-out
concept must be alive at the anchor (check readout/heat before
recommending — self-gating); written words never change; and when rewrites
come out identical, say so plainly and offer exactly: earlier anchor, heat
check on the take-out word, a take-out word from the current readout, or a
slightly stronger push within the green band. Your castle→cave transcript
would now be caught twice: the suggestion step must name the anchor word,
and the post-swap step sees "IDENTICAL"/"take-out word before the anchor"
in STATUS.

**Rev 4 live-eyeball items:** how Maggie actually sounds on your machines
(pitch/rate are one-line tunables); whether the adopt-button copy reads well
to a child; a real castle→cave replay of your transcript to judge the
coaching; and whether the divergence-point status line helps or overwhelms
the model's answers.

## Rev 3 — mute, Thought Bubble, Maggie, tooltip→guide bridge

**⚠ vg-core.js CHANGED: v1 `281c49bb21feb50b` → v1.1 `08925280f31b4f9e`.**
Refresh the project-knowledge copy TODAY; vg-core-v1.1.diff is attached for
Claude Code's parity gate. Two additions, both seams, no behavior changes to
existing paths:

1. **Speech mute (core).** `#vgMute` (🔊/🔇) in the panel controls, persisted
   per app (`jlens-guide-muted`). Muted speech takes the existing read-along
   timing path, so tour pacing and spotlight rhythm survive with the voice
   off; muting mid-sentence cancels synthesis and the pacing takes over at
   the next chunk. Words always land in the log either way.
2. **Tooltip→guide bridge (core seam per kickoff spec, proposed rev 1,
   built on Ken's go).** Adapter supplies `topics: [{id, target
   (selector|fn), oneLiner, guideQuestion}]`; core owns the JS tooltip
   (oneLiner + "Ask Maggie" button), `api.askAbout(topicId)` (opens the
   panel and submits the seeded question through the normal ask pipeline —
   tour-pause, history, STATUS, DO handling all inherited), and
   `api.bindTopics()` for late-rendered targets. **Core strips the native
   `title` from every bound element** so the registry and hover copy cannot
   double up or drift; the titles stay in the static HTML as a no-JS
   fallback. Test hook: `__guide.topics`, `__guide.askAbout`,
   `__guide.muted`. `VoiceGuide.version` → 1.1.

**Adapter rev 3:** 8-topic registry (surprise, max, raw, top20, modes,
strength, surprising-rewrites, swap) reusing the kickoff's paste-ready copy
as oneLiners, with visitor-voice guideQuestions (raw = the kickoff's example
verbatim). Persona: **Maggie the magpie detective** — mascot 🐦‍⬛, thinkFace
🔍 (peering through the loupe); the J-lens is narrated as her jeweler's
loupe, readout chips as the shiny clues she collects; tour/greeting/remarks
rewritten to the detective register, "where did it decide?" kept.

**App rename (patcher rev 3):** title, h1 (now 💭 Thought Bubble), and the
tab-title progress suffix. "J-lens" remains the *lens's* name everywhere;
element ids untouched; the guide's storage id stays `jlens` so existing
panel/mute/key preferences survive the rename.

**Rev 3 judgment calls — bless or veto:** (a) the name "Maggie" (you
specified species and prop, not a name); (b) 🐦‍⬛ is a ZWJ emoji sequence —
older systems render it as bird+black square (fallback: plain 🐦); (c) h1
emoji 💭; (d) the 8-topic set (chips/heat strip left out: dynamic targets).

**Rev 3 live-eyeball items:** tooltip placement and hover-intent feel (jsdom
rects are all zeros, geometry is unproven); the tip persists while the
pointer crosses into it — check the 350 ms grace feels right; ZWJ magpie on
your target devices; mute mid-tour UX.

## Rev 2 — artifact worker-boot fix (field bug)

**Symptom (Ken, live artifact):** file drops did nothing;
`Uncaught SecurityError: Failed to construct 'Worker': Script at
'blob-request://…' cannot be accessed from origin
'https://www.claudeusercontent.com'`.

**Diagnosis:** the artifact runtime shims the top window's
`URL.createObjectURL` to return `blob-request://` tokens; the native
`Worker` constructor rejects that scheme *synchronously* at the app's
top-level `const worker = new Worker(URL.createObjectURL(...))` — the whole
app script block died at parse, so the drop zone was never wired.
Standalone browsers have no shim, hence worked. The nested compute pool
constructs its workers *inside* the Engine worker from unshimmed natives and
is unaffected (and `Pool.init` is try/catch'd anyway) — **so this stayed a
main-thread pre-fix; the worker blob is untouched** (Claude Code's lane
preserved).

**Fix (pre-fix 4 in the patcher):** three-tier construction cascade —
(1) the page's `createObjectURL` (normal browsers), (2) a hidden
same-origin iframe's *native* `createObjectURL` (fresh realm the shim never
patched; keeps the worker's true origin, so its IndexedDB dict cache,
`crypto.subtle` hashing and nested pool behave exactly as standalone),
(3) `data:` URL last resort (opaque origin: computes fine, worker-side cache
unavailable, pool may degrade to single-worker — both degrade gracefully).

**Tested headless (6 new checks):** the suite's Worker stub now rejects
`blob-request://` exactly like the real constructor; a simulated-artifact
instance proves the app survives, falls through to a working construction,
round-trips the worker source intact, and runs the full files→story flow.
**Honest limit:** jsdom has no native `createObjectURL`, so the simulation
exercises tiers 1→3; tier 2 (the iframe-native path, the one that should win
in the real artifact) is only provable live. If the artifact *also* shims
child-iframe realms, tier 3 catches it — at the cost of the worker-side dict
cache in artifacts only. **Please retest the drop flow in the artifact and
tell me which tier won** (console-check: `worker` boots silently either way;
if dictionaries rebuild on every artifact visit, tier 3 is active).

## What shipped

**Pre-fixes (app-side, per kickoff, before the splice)**
1. Temperature slider visible name `heat` → `surprise`, kickoff tooltip; `use
   story heat (advanced)` → `surprising rewrites (advanced)`, kickoff tooltip.
   Element ids unchanged.
2. Strength slider: green recommended band 0.2–0.5 drawn under the track
   (range is 0–1.5 → 13.3%..33.3%); hint now says "stay in the green band".
3. Dictionary progress copy → "one-time setup: building the lens's
   word-directions (cached after today)… L{n}, {pct}%".
4. (Bonus, kickoff's paste-ready tooltip copy) `title` tooltips on max, raw,
   top-20. Readout-chip heat tooltip already existed in-app.

The kickoff also says "update the done-line … that says heat-as-temperature" —
the done-line in this build never mentioned heat, so there was nothing to fix
there; noted rather than silently skipped.

**Adapter (11 tour stops on the kickoff's 7-step spine):** hello → files
(skipIf loaded) → starter (vase story; don't-clobber guard knows the app's
hardcoded default) → your-move (tour never presses analyze; waits) → story
(invites a click; picks a mid-story token itself if the player abstains) →
readout (reads the live L7 row: "holding in mind: …", disposed-to-say) → DIFF
(guide switches the view; "green words are its secret plans") → heat ritual
(spots a promising j-only chip, "where did it decide?") → swap (moat story;
suggests vase→ball live from the pieces; "that button is entirely your move")
→ panes (same-dice, left-to-right) → wrap (raw = honest view, pink fragments,
"the lens gets smarter the longer your story gets").

**Verbs:** SHOW / SELECTTOKEN / SETMODE / TOGGLERAW / TOGGLETOP20 / HEAT /
SETSWAP frictionless with validation; ANALYZE / GENERATE / SWAP dialog-gated
(validate-before-ask; ratify text names words + anchor); STOP validated but
frictionless. System prompt encodes the kickoff glossary verbatim in meaning
(disposed-to-say vs blurt-out, DIFF green, L4–L8 rationale, thin readouts,
fragments/Zog, raw, swap two-rewrite + self-gating + moat, heat strip), live
vocab count from the piece map, full 5-panel enumeration, consent-scope with
"SETSWAP is never consent to run SWAP".

**Layout:** mirror `.grid2` stack at 1402 (=1100+302), softening band
`.swapgrid` stack at 1202 (=900+302), narrow dock ≤700. Palette mapped from
the app's colors in `#vgAppStyle`. Takeover: pointerdown+keydown.

**No vg-core.js edits.** None were needed; nothing to refresh in project
knowledge.

## What the suite proves vs. what needs your eyeballs

Proven headless (105 checks): boot with zero page errors; pre-fixes; generated
stylesheet asserted against `__guide.layout`; every adapter selector exists in
the built HTML; greeting/key dialog/keyed storage; don't-clobber both ways;
full tour to done with a story and cold (skips + honest copy); pause/resume
remarks incl. forced-reset suppression and two-fact cap; all verbs drive the
real controls; gating (No preserves, Yes presses swapBtn → real `noswap`
generate with promptIds; validity-before-asking silent no-ops); confirm
wrapper with-trigger and press-again tiers; keyless chain order + DO strip +
STATUS placement + normalizeReply; keyed routing beats keyless; mic-policy
explainer with the adapter key hint; below-the-fold readout announce at
stacked width; synthetic events never pause; `node --check` on all four
script blocks.

Needs a live browser: real TTS/recognition; real keyless calls in an artifact;
spotlight geometry on the dense panel 4 and the strength-band alignment against
the real track (thumb-travel vs track-edge is approximate); 1300px and 600px
layouts (kickoff carried-forward); whether the heat ritual pays off on the
curated starters with the real model (my fake readout is rigged to be
interesting); tour pacing at word speed.

## Judgment calls — bless or veto

1. **Persona: "Scope" 🔭, observatory keeper** (kickoff open decision 1).
   Distinct from Pixel Pal and the Tiny Mind rooms; "observatory watching a
   tiny mind" frames pointing-not-touching naturally. One-line change if
   vetoed.
2. **Slider rename "surprise" implemented** (open decision 2 — you hadn't
   blessed a name; the kickoff floated it as candidate). Copy-level only,
   ids stable; trivially re-patchable.
3. **Verb-gating split.** The kickoff's "all story/state-moving verbs gated to
   explicit request" is ambiguous about whether the list after the colon is
   the gated set or the whole verb table. I dialog-gated only ANALYZE /
   GENERATE / SWAP (they replace the story or start heavy compute) and made
   STOP frictionless-but-validated — a ratification dialog on STOP would
   outlive the generation it halts. SELECTTOKEN/SETMODE/toggles/HEAT/SETSWAP
   are reversible inspection, frictionless. All remain prompt-gated in prose.
   This is the call most worth red-teaming: strictest reading gates
   everything, which I think is unusable friction — but it's your consent
   model.
4. **Tour selects a token itself** if the player doesn't within a beat
   (mid-story, ~60%). Keeps the readout stop honest without stalling; the
   kickoff's "tour never presses story-moving buttons" reading I applied is
   that token *selection* is inspection, not a story move.
5. **11 stops** expanded from the 7-step spine (added files-skipIf, your-move,
   panes as separate stops).
6. **Key dialog + 🔑 button ported from Piskel** (app has no LLM plumbing or
   settings surface).
7. **Adapter-owned toast** (`#vgToast`) — the app has no notifier; used for
   hide/confirm-arm/below-fold messages.
8. **Vase starter** ("Ben broke his mom's favorite vase…") as the tour's
   hide/secret-class story; swap suggestion tailors live (hole→castle if
   present, else vase→ball).

## Doc/kickoff field-test findings (for the v4 bank)

- **Kickoff verb-table grammar is ambiguous** (finding 3 above): the doc
  template should force kickoffs to tag each verb `gated:dialog`,
  `gated:prompt-only`, or `free`, so the adapter never has to parse prose.
- **Kickoff referenced a README fingerprint not present in the chat**; the
  baseline rule in v3 should say what to do when the quoted fingerprint's
  *source* is missing (I fell back to feature markers + a loud note).
- **v3 has no guidance on gated-verb waits in suites**: `__guide.do` on a
  gated verb resolves only when the dialog is answered; my first run
  deadlocked awaiting it. Worth one sentence in the suite section ("launch
  gated do() un-awaited; answer the dialog; then await it").
- **Confirm-wrapper testing note**: any test click within 3 s arms the
  with-trigger tier; the press-again tier can only be tested after the
  trigger window expires. Also worth a sentence.
- **Snapshot granularity**: re-analyzing *identical* text is invisible to a
  {lastText, nTok} snapshot. Harmless here (remark stays silent), but v4
  could suggest a per-capture nonce if an app makes "same text re-run"
  meaningful.

## Propose-only: tooltip→guide bridge (core seam, not built)

Kickoff asks for a registry so tooltip-bearing controls can route "tell me
more" into the guide. Proposed seam shape, for you and Claude Code:

- `api.askAbout(topicId, {clickEl})` on the core api: looks up
  `adapter.topics[topicId] = {q: 'visitor-voice question', ground: 'extra
  grounding sentence'}`, logs the question as if typed, injects `ground` into
  that one call's system prompt, honors pause/QA history.
- Core also exposes `api.bindTopic(el, topicId)` which decorates the element
  (a small ⓘ affordance) and wires the click; adapters never touch panel DOM.
- Rationale for core ownership: pause semantics, QA history, and prompt
  assembly are core-owned; only the topic table is app truth.

If you bless the shape, it's a ~30-line core change + a topics table here —
flagging loudly now: that WOULD be a vg-core.js edit, project-knowledge copy
to refresh the same day.

## Open items for you

1. Bless/veto the eight calls above (esp. persona, "surprise", gating split).
2. README fingerprint for the Phase 1.5 build, if one exists.
3. App name is still the placeholder "J-Lens Explorer" (kickoff open
   decision 3) — say the word and the patcher grows one more substitution.
4. `askAbout` seam: bless shape → route to Claude Code or me?
