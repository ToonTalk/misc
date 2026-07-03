/* Smoke suite for the studio voice-guide layer.
   Run: node smoke-guide.mjs
   Headless notes: jsdom has no TTS (read-along timing path, set to
   0ms/word), no SpeechRecognition, and a null canvas 2d context
   (the app's renderCanvasSafe catches that; we filter its noise). */
import { JSDOM, VirtualConsole } from 'jsdom';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const here = dirname(fileURLToPath(import.meta.url));
const HTML = readFileSync(join(here, 'space_games_construction_kit.html'), 'utf8');

let pass = 0, fail = 0;
const failures = [];
function check(name, cond, detail) {
  if (cond) { pass++; console.log('  ok  ' + name); }
  else { fail++; failures.push(name + (detail ? ' — ' + detail : '')); console.log('  FAIL ' + name + (detail ? ' — ' + detail : '')); }
}
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function until(fn, ms = 8000, step = 25) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) { try { if (fn()) return true; } catch (e) {} await sleep(step); }
  return false;
}

const IGNORABLE = /getContext|clearRect|canvas|Not implemented|SpeechSynthesis|scrollIntoView|AudioContext/i;
function makeDom({ url = 'https://localhost/', beforeParse = null, collect = null } = {}) {
  const vc = new VirtualConsole();
  vc.on('jsdomError', e => { if (!IGNORABLE.test(String(e && e.message))) collect && collect.push('jsdomError: ' + e.message); });
  vc.on('error', (...a) => { const s = a.map(String).join(' '); if (!IGNORABLE.test(s)) collect && collect.push('console.error: ' + s); });
  return new JSDOM(HTML, {
    url, runScripts: 'dangerously', pretendToBeVisual: true, virtualConsole: vc,
    beforeParse(window) {
      // the app touches these; keep headless quiet and deterministic
      window.HTMLCanvasElement.prototype.getContext = () => null;
      if (beforeParse) beforeParse(window);
    }
  });
}

/* ---------- 1. fresh load ---------- */
{
  console.log('\n[1] fresh load');
  const errs = [];
  const dom = makeDom({ collect: errs });
  const w = dom.window, d = w.document;
  await sleep(150);
  const app = () => w.__guide.app;
  check('app state initialised', !!app().state && app().state.currentProject === 'rescue');
  check('guide hook exposed', !!w.__guide && w.__guide.state === 'idle');
  check('guide panel present', !!d.getElementById('vgPanel'));
  check('greeting in transcript', d.getElementById('vgLog').children.length >= 1);
  check('panel open by default (body reflow class)', d.body.classList.contains('vg-open'));
  check('no unexpected console/jsdom errors', errs.length === 0, errs.slice(0, 3).join(' | '));
  check('docked-reflow breakpoints shipped', HTML.includes('max-width:1482px') && HTML.includes('body.vg-open .layout') && HTML.includes('max-width:1560px'));
  check('narrow widths bottom-dock instead of overlaying', HTML.includes('margin-bottom:302px') && HTML.includes('translateY(102%)'));
  d.getElementById('vgHide').click();
  check('hide removes the reflow class', !d.body.classList.contains('vg-open'));
  check('hide fires a toast pointing at the restore tab', d.getElementById('toast').classList.contains('show') && /Guide tab/.test(d.getElementById('toast').textContent));
  check('restore tab carries a visible label', /Guide/i.test(d.getElementById('vgTab').textContent));
  d.getElementById('vgTab').click();
  check('tab click restores the panel', d.body.classList.contains('vg-open'));

  /* ---------- 2. id / global audit ---------- */
  console.log('\n[2] id and app-global audit');
  const ids = ['vgPanel','vgTab','vgHead','vgFace','vgTitle','vgHide','vgControls','vgMain','vgMic','vgSkip','vgEnd','vgLog','vgStatus','vgTypeRow','vgIn','vgGo',
               'tabTeam','tabBrief','tabResources','tabInspector','leftContent','rightContent','storyGatePanel','stageWrap','stage','runBtn','pauseBtn','resetBtn',
               'projectSwitch','feedbackPanel','aiSettingsBtn','exportBtn','importBtn','helpBtn'];
  check('every referenced id exists', ids.every(id => d.getElementById(id)), ids.filter(id => !d.getElementById(id)).join(','));
  const fnGlobals = ['saveState','renderAll','answer','optionsFor','attachBehavior','switchProject','currentRuntime','selectedObject',
                   'readyForStudio','isUnlocked','hasBehavior','availableBehaviors','buildAgentSystemPrompt','callLLM','currentAIKey','extractError'];
  check('every referenced app function exists on window', fnGlobals.every(gl => typeof w[gl] === 'function'), fnGlobals.filter(gl => typeof w[gl] !== 'function').join(','));
  const lexGlobals = ['state','llmConfig','sessionApiKeys','BEHAVIORS','TEAM','PROJECTS','RESOURCE_NAMES'];
  check('every referenced lexical global reachable via hook', lexGlobals.every(gl => app()[gl] !== undefined), lexGlobals.filter(gl => app()[gl] === undefined).join(','));
  check("buildAgentSystemPrompt('guide') safe fallback",
    (() => { const s = w.buildAgentSystemPrompt('guide'); return /First Day at the Game Studio/.test(s) && /CURRENT APP STATE/.test(s) && !/undefined/.test(s); })());

  /* ---------- 3. selector audit, pre-studio stops ---------- */
  console.log('\n[3] spotlight selectors resolve (pre-studio state)');
  const g = w.__guide;
  const active = g.steps.filter(st => !(st.skipIf && st.skipIf()));
  check('pre-studio tour has 9 stops', active.length === 9, active.map(s => s.name).join(','));
  for (const st of active) {
    if (st.prep) { try { st.prep(); } catch (e) {} }
    let els = [];
    if (typeof st.spot === 'function') els = [].concat(st.spot() || []);
    else els = Array.from(d.querySelectorAll(st.spot));
    els = els.filter(Boolean);
    check(`stop "${st.name}" spot resolves tightly`, els.length >= 1 && els.every(e => e && e.classList !== undefined),
      typeof st.spot === 'string' ? st.spot : '(fn)');
  }
  // spotlight tightness spot-checks: the-boss glows the accept button itself, not the card
  { const st = g.steps.find(s => s.name === 'the-boss'); st.prep();
    const el = st.spot();
    check('the-boss spot is the accept button', el && el.getAttribute && el.getAttribute('data-answer') === 'acceptBrief'); }
  app().state.tabLeft = 'team'; w.renderAll();

  /* ---------- 4. tour lifecycle: start, transcript, done ---------- */
  console.log('\n[4] tour lifecycle');
  g.setWordMs(0);
  const before = d.getElementById('vgLog').children.length;
  g.start();
  check('tour running after start', g.state === 'running');
  check('skip/end buttons visible while live', d.getElementById('vgSkip').style.display === 'flex');
  const done = await until(() => g.state === 'done', 20000);
  check('tour reaches done', done, 'state=' + g.state);
  check('all 9 pre-studio narrations landed in transcript', d.getElementById('vgLog').children.length >= before + 9);
  check('spotlight cleared at end', d.querySelectorAll('.vg-spot').length === 0);

  /* ---------- 5. skip and end ---------- */
  console.log('\n[5] skip and end');
  g.start(); await until(() => g.state === 'running', 2000);
  const curBefore = g.cur; g.skip();
  await until(() => g.cur > curBefore || g.state === 'done', 3000);
  check('skip advances past the interrupted stop', g.cur > curBefore || g.state === 'done');
  g.end();
  check('end returns to idle and clears spotlight', g.state === 'idle' && d.querySelectorAll('.vg-spot').length === 0);

  /* ---------- 6. provenance: pause snapshot -> resume-remark wording ---------- */
  console.log('\n[6] resume-remark wording and side-effect suppression');
  let s0 = g.snap();
  w.answer('boss', 'acceptBrief');                        // real scripted path; also force-unlocks missionBrief
  let d1 = g.diff(s0);
  check('brief acceptance reported', /rescue assignment/.test(d1), d1);
  check('forced missionBrief unlock suppressed', !/Mission brief/.test(d1) && !/gathered/.test(d1), d1);

  s0 = g.snap();
  w.answer('artist', 'placeholderArt');                   // a genuine unlock, not a side effect
  d1 = g.diff(s0);
  check('genuine resource unlock reported by visible name', /gathered/.test(d1) && /Placeholder rescue art/.test(d1), d1);

  // walk the real golden path to open the studio
  w.answer('scientist', 'rescueMotion');
  w.answer('scientist', 'rescueMomentum');
  w.answer('programmer', 'makeBehavior');
  check('golden path unlocks first two cards', w.isUnlocked('horizontalMotion') && w.isUnlocked('rockThrower'));
  s0 = g.snap();
  app().state.tabLeft = 'brief'; w.renderAll();
  const openBtn = d.querySelector('[data-open-studio]');
  check('open-studio button enabled when ready', openBtn && !openBtn.disabled);
  openBtn.click();
  d1 = g.diff(s0);
  check('studio opening reported, forced tab/selection changes suppressed', /opened the game creation area/.test(d1) && !/tab/.test(d1) && !/looking at/.test(d1), d1);

  s0 = g.snap();
  w.attachBehavior('astronaut', 'horizontalMotion');      // forces selected/side/tabRight — must not be narrated
  d1 = g.diff(s0);
  check('attachment reported with names', /Horizontal motion/.test(d1) && /Astronaut/.test(d1), d1);
  check('forced inspector flip suppressed', !/inspector/i.test(d1) && !/side/.test(d1), d1);

  s0 = g.snap();
  app().state.tabLeft = 'team'; w.renderAll();                // a minor facet, alone
  d1 = g.diff(s0);
  check('minor facet only speaks when nothing bigger did', /Team room/.test(d1), d1);
  check('no change -> no remark', g.diff(g.snap()) === '');

  /* ---------- 7. selector audit, studio stops ---------- */
  console.log('\n[7] spotlight selectors resolve (studio state)');
  for (const name of ['the-stage','resources','the-backside','live-run','debrief']) {
    const st = g.steps.find(s => s.name === name);
    check(`stop "${name}" no longer skipped`, !(st.skipIf && st.skipIf()));
    if (st.prep) { try { st.prep(); } catch (e) {} }
    let els = typeof st.spot === 'function' ? [].concat(st.spot() || []) : Array.from(d.querySelectorAll(st.spot));
    check(`stop "${name}" spot resolves`, els.filter(Boolean).length >= 1);
  }
  { const st = g.steps.find(s => s.name === 'two-projects');
    check('two-projects still skipped before lunar unlock', !!(st.skipIf && st.skipIf())); }

  /* ---------- 7b. studio-state tour run: during-action path, untrusted passthrough ---------- */
  console.log('\n[7b] studio tour run (during-action + untrusted passthrough)');
  g.setWordMs(0);
  const logN = d.getElementById('vgLog').children.length;
  const cardsBefore = app().state.objects.astronaut.behaviors.map(b => b.id).join(',');
  g.start();
  await until(() => g.state === 'running', 2000);
  d.getElementById('helpBtn').click();                    // synthetic = untrusted: must NOT pause
  d.getElementById('closeHelpBtn').click();
  check('synthetic clicks do not auto-pause (isTrusted gate)', g.state === 'running');
  const done2 = await until(() => g.state === 'done', 25000);
  check('studio tour reaches done through the live-run stop', done2, 'state=' + g.state);
  check('live-run demo left attachments intact', app().state.objects.astronaut.behaviors.map(b => b.id).join(',') === cardsBefore);
  check('playtest reset after the demo (not left running)', !w.currentRuntime().running);
  check('studio tour narrated 11 stops', d.getElementById('vgLog').children.length >= logN + 11,
    String(d.getElementById('vgLog').children.length - logN));

  /* ---------- 8. DO gating: app rules hold underneath the whitelist ---------- */
  console.log('\n[8] DO protocol gating (story verbs now player-ratified)');
  const modal8 = () => d.getElementById('vgConfirm');
  await g.do({ verb: 'ATTACH', args: 'oxygenTimer astronaut' });      // locked card: invalid, so no dialog either
  check('ATTACH refuses a locked card without even asking', !w.hasBehavior(app().state.objects.astronaut, 'oxygenTimer') && !(modal8() && modal8().classList.contains('show')));
  let p8 = g.do({ verb: 'ATTACH', args: 'rockThrower astronaut' });   // unlocked: ratification dialog
  await until(() => modal8() && modal8().classList.contains('show'), 2000);
  check('ATTACH proposes and waits for the player', /attach "Horizontal rock thrower" to the Astronaut/.test(d.getElementById('vgConfirmMsg').textContent) && !w.hasBehavior(app().state.objects.astronaut, 'rockThrower'));
  d.getElementById('vgConfirmNo').click(); await p8;
  check('Cancel leaves the card unattached', !w.hasBehavior(app().state.objects.astronaut, 'rockThrower'));
  p8 = g.do({ verb: 'ATTACH', args: 'rockThrower astronaut' });
  await until(() => modal8().classList.contains('show'), 2000);
  d.getElementById('vgConfirmYes').click(); await p8;
  check('Yes attaches via the real handler', w.hasBehavior(app().state.objects.astronaut, 'rockThrower'));
  await g.do({ verb: 'PROJECT', args: 'lunar' });                      // locked project
  check('PROJECT respects the lunar lock', app().state.currentProject === 'rescue');
  await g.do({ verb: 'ANSWER', args: 'boss bogusOption' });            // invalid option id: no dialog, no effect
  check('ANSWER validates option ids against optionsFor', !app().state.log.some(l => /bogus/i.test(l.text || '')) && !modal8().classList.contains('show'));
  await g.do({ verb: 'TAB', args: 'brief' });
  check('TAB drives the real tab button', app().state.tabLeft === 'brief');
  await g.do({ verb: 'SHOW', args: 'ai_setup' });
  check('SHOW spotlights the named target', d.getElementById('aiSettingsBtn').classList.contains('vg-spot'));
  g.unspot();
  dom.window.close();
}

/* ---------- 8b. ANSWER ratification: proposing a scripted choice ---------- */
{
  console.log('\n[8b] ANSWER goes through the ratification dialog');
  const dom = makeDom();
  const w = dom.window, d = w.document, g = w.__guide;
  await sleep(120);
  const p = g.do({ verb: 'ANSWER', args: 'boss acceptBrief' });
  await until(() => { const m = d.getElementById('vgConfirm'); return m && m.classList.contains('show'); }, 2000);
  check('dialog names the choice and the teammate', /guide wants to choose/.test(d.getElementById('vgConfirmMsg').textContent) && g.app.state.briefAccepted === false);
  d.getElementById('vgConfirmYes').click(); await p;
  check('ratified ANSWER clicks the real scripted button', g.app.state.briefAccepted === true);
  dom.window.close();
}

/* ---------- 9. typed-ask path, keyless-first model chain, DO strip, re-baseline ---------- */
{
  console.log('\n[9] typed ask: keyless chain, DO stripping, provenance re-baseline');
  const dom = makeDom({ url: 'https://abc123.claudeusercontent.com/' });   // artifact hostname -> keyless path
  const w = dom.window, d = w.document, g = w.__guide;
  await sleep(120);
  g.setWordMs(0);
  check('artifact context detected from hostname', g.inClaude === true);
  check('keyless chain is sonnet-5 then sonnet-4-6', g.keylessModels.join(',') === 'claude-sonnet-5,claude-sonnet-4-6');

  const calls = [];
  w.fetch = async (url, opts) => {
    const body = JSON.parse(opts.body); calls.push({ url, body });
    if (calls.length === 1)
      return { ok: false, status: 400, json: async () => ({ error: { message: 'model: claude-sonnet-5 not found' } }) };
    return { ok: true, status: 200, json: async () => ({ content: [{ type: 'text', text: 'The Run button starts a playtest and the horizontalMotion card moves things.\nDO: TAB brief' }] }) };
  };
  g.pauseCore();                                       // establish a pause snapshot to re-baseline
  const snapTabBefore = g.pauseSnap.tabLeft;
  await g.ask('where do I run a playtest?');
  await until(() => Array.from(d.getElementById('vgLog').children).some(el => /Run button starts/.test(el.textContent)), 4000);
  check('grounded system prompt reused + override appended',
    calls.length >= 1 && /METAGAME CONTEXT/.test(calls[0].body.system) && /VOICE-GUIDE OVERRIDE/.test(calls[0].body.system) && /CURRENT APP STATE/.test(calls[0].body.system));
  check('explicit-only verbs documented in override', /allowed ONLY when the visitor/.test(calls[0].body.system));
  check('first keyless attempt is claude-sonnet-5', calls[0] && calls[0].body.model === 'claude-sonnet-5');
  check('fallback retry is claude-sonnet-4-6', calls[1] && calls[1].body.model === 'claude-sonnet-4-6');
  check('question flattened into single-turn user prompt', /The visitor now asks the guide/.test(calls[0].body.userPrompt || calls[0].body.messages[0].content));
  const up0 = calls[0].body.messages[0].content;
  check('fresh STATUS block after history, before the question', /STATUS RIGHT NOW/.test(up0) && up0.indexOf('STATUS RIGHT NOW') < up0.indexOf('The visitor now asks'));
  check('status carries live studio state', /Studio open: false/.test(up0));
  check('status-outranks-history rule in the override', /status wins/.test(calls[0].body.system));
  check('interaction facts in the override (no invented controls)', /no drag and drop/.test(calls[0].body.system) && /Attach to <object>/.test(calls[0].body.system));
  check('point-not-describe rule in the override', /ALWAYS end with a DO line/.test(calls[0].body.system));
  check('consent-scope rule in the override (no escalation on "please do")', /consent to jump, never to attach/.test(calls[0].body.system) && /Never escalate/.test(calls[0].body.system));
  check('id-to-title roster binds DO ids to prose names', /designer \(Assistant game designer\)/.test(calls[0].body.system) && /artist \(Artist \/ animator\)/.test(calls[0].body.system));
  const spoken = Array.from(d.getElementById('vgLog').children).map(el => el.textContent);
  check('DO line stripped before speaking', spoken.some(t => /Run button starts/.test(t)) && !spoken.some(t => /DO:/.test(t)));
  check('prose normalized to visible names (after DO extraction)', spoken.some(t => /Horizontal motion card/.test(t)) && !spoken.some(t => /horizontalMotion/.test(t)));
  check('DO executed through the real tab button', w.__guide.app.state.tabLeft === 'brief');
  check('pause snapshot re-baselined after guide-driven DO', g.pauseSnap && g.pauseSnap.tabLeft === 'brief' && snapTabBefore !== 'brief');

  // second ask: history carried in the flattened prompt
  await g.ask('and how do I stop it?');
  await until(() => calls.length >= 3, 3000);
  const last = calls[calls.length - 1].body;
  check('Q&A history flattened into later prompts', /Conversation so far/.test(last.messages ? last.messages[0].content : ''));
  dom.window.close();
}

/* ---------- 10. keyed path routes through the app's own callLLM ---------- */
{
  console.log("\n[10] configured key wins: app's callLLM plumbing reused");
  const dom = makeDom({ url: 'https://abc123.claudeusercontent.com/' });  // even in an artifact
  const w = dom.window, g = w.__guide;
  await sleep(120);
  g.setWordMs(0);
  w.__guide.app.sessionApiKeys.openai = 'sk-test';                    // the app's own session-key slot
  let seen = null;
  w.callLLM = async (sys, usr) => { seen = { sys, usr }; return 'Reset puts everything back.'; };
  await g.ask('what does reset do?');
  await until(() => !!seen, 3000);
  check('keyed ask routed through callLLM, not fetch', !!seen);
  check('same grounding + override on the keyed path', seen && /METAGAME CONTEXT/.test(seen.sys) && /VOICE-GUIDE OVERRIDE/.test(seen.sys));
  dom.window.close();
}

/* ---------- 11. no key, not in an artifact: friendly steer ---------- */
{
  console.log('\n[11] no AI available: steer to Live AI setup');
  const dom = makeDom();                                   // localhost, no key
  const w = dom.window, d = w.document, g = w.__guide;
  await sleep(120);
  g.setWordMs(0);
  await g.ask('why does the astronaut drift?');
  const ok = await until(() => Array.from(d.getElementById('vgLog').children).some(el => /Live AI setup/.test(el.textContent)), 3000);
  check('steer names the Live AI setup button and the artifact option', ok &&
    Array.from(d.getElementById('vgLog').children).some(el => /Claude artifact/.test(el.textContent)));
  check('steer spotlights the setup button', d.getElementById('aiSettingsBtn').classList.contains('vg-spot'));
  dom.window.close();
}

/* ---------- 12. simulated artifact: mic blocked by policy ---------- */
{
  console.log('\n[12] simulated artifact sandbox: mic by policy, not by error');
  const dom = makeDom({
    url: 'https://abc123.claudeusercontent.com/',
    beforeParse(window) {
      Object.defineProperty(window.document, 'permissionsPolicy', {
        value: { allowsFeature: f => f !== 'microphone' }, configurable: true
      });
    }
  });
  const w = dom.window, d = w.document, g = w.__guide;
  await sleep(120);
  g.setWordMs(0);
  check('policy block detected at load', g.micPolicyBlocked === true);
  check('mic button dimmed immediately', d.getElementById('vgMic').classList.contains('vg-off'));
  check('mic tooltip explains before any press', /blocked in this sandbox/.test(d.getElementById('vgMic').title));
  d.getElementById('vgMic').click();
  const ok = await until(() => Array.from(d.getElementById('vgLog').children).some(el => /no permission pop-up can ever appear/.test(el.textContent)), 3000);
  const txt = Array.from(d.getElementById('vgLog').children).map(el => el.textContent).join(' ');
  check('explainer: no prompt will ever appear here', ok);
  check('explainer steers to the typed box', /Type your question in the box/.test(txt));
  check('explainer steers to the standalone file + own key', /normal browser tab/.test(txt) && /API key/.test(txt));
  dom.window.close();
}

/* ---------- 13. artifact mode: the whole team answers keyless ---------- */
{
  console.log("\n[13] app's own Live AI goes keyless in an artifact");
  const dom = makeDom({ url: 'https://abc123.claudeusercontent.com/' });
  const w = dom.window, d = w.document, g = w.__guide;
  await sleep(120);
  g.setWordMs(0);
  const calls = [];
  w.fetch = async (url, opts) => { calls.push({ url, body: JSON.parse(opts.body), headers: (opts.headers || {}) });
    return { ok: true, status: 200, json: async () => ({ content: [{ type: 'text', text: 'Momentum keeps things moving.' }] }) }; };
  await w.askRoleAI('scientist', 'why do things keep moving?');
  check('teammate ask went out with no key configured', calls.length >= 1);
  check('keyless teammate ask tries claude-sonnet-5 first', calls[0] && calls[0].body.model === 'claude-sonnet-5');
  check('no api key header on the keyless call', !calls[0].headers['x-api-key']);
  check('key gate not tripped (no settings modal, no key toast)',
    !d.getElementById('aiModal').classList.contains('show') && !/Add an API key/.test(d.getElementById('toast').textContent));
  check('reply landed in the scientist transcript', (g.app.state.aiChats.scientist || []).some(e => /Momentum keeps things moving/.test(e.a)));
  check('currentAIKey restored after the call', w.currentAIKey() === '');
  check('settings modal carries the artifact note', /no key at all/.test(d.getElementById('aiModal').textContent));
  dom.window.close();
}

/* ---------- 14. a configured key still wins, on the user's provider ---------- */
{
  console.log('\n[14] configured key takes priority over keyless');
  const dom = makeDom({ url: 'https://abc123.claudeusercontent.com/' });
  const w = dom.window, d = w.document, g = w.__guide;
  await sleep(120);
  g.setWordMs(0);
  g.app.llmConfig.provider = 'anthropic';
  g.app.sessionApiKeys.anthropic = 'sk-real';
  const calls = [];
  w.fetch = async (url, opts) => { calls.push({ url, headers: opts.headers || {}, body: JSON.parse(opts.body) });
    return { ok: true, status: 200, json: async () => ({ content: [{ type: 'text', text: 'Gravity pulls things down.' }] }) }; };
  await w.askRoleAI('scientist', 'what does gravity do?');
  check('keyed ask routed through the original provider path', calls.length >= 1 && calls[0].headers['x-api-key'] === 'sk-real');
  check("keyed ask uses the app's configured model, untouched", calls[0] && calls[0].body.model === g.app.llmConfig.models.anthropic);
  dom.window.close();
}

/* ---------- 15. confirm(): in-page dialog with re-trigger; fallbacks intact ---------- */
{
  console.log('\n[15] confirm(): in-page dialog, cancel, backdrop, fallbacks');
  const dom = makeDom({ beforeParse(window) { window.URL.createObjectURL = () => 'blob:x'; window.URL.revokeObjectURL = () => {}; } });
  const w = dom.window, d = w.document, g = w.__guide;
  await sleep(120);
  w.answer('boss', 'acceptBrief');
  check('precondition: state to lose', g.app.state.briefAccepted === true);

  d.getElementById('resetAllBtn').click();
  const modal = d.getElementById('vgConfirm');
  check('press shows the in-page dialog instead of resetting', modal && modal.classList.contains('show') && g.app.state.briefAccepted === true);
  check('dialog carries the original confirm message', /Reset the prototype state\?/.test(d.getElementById('vgConfirmMsg').textContent));
  check('reset dialog hints at exporting first', /export it first/i.test(d.getElementById('vgConfirmHint').textContent));
  d.getElementById('vgConfirmExtra').click();
  check('Export-first opens the export modal and stands down', d.getElementById('exportModal').classList.contains('show') && !modal.classList.contains('show') && g.app.state.briefAccepted === true);
  d.getElementById('exportModal').classList.remove('show');
  d.getElementById('resetAllBtn').click();
  d.getElementById('vgConfirmYes').click();
  await sleep(50);
  check('Yes re-triggers the button and the reset goes through', g.app.state.briefAccepted === false && g.app.state.studioOpen === false);
  check('dialog closed after Yes', !modal.classList.contains('show'));

  w.answer('boss', 'acceptBrief');
  d.getElementById('resetAllBtn').click();
  d.getElementById('vgConfirmNo').click();
  await sleep(30);
  check('Cancel keeps the state and closes the dialog', g.app.state.briefAccepted === true && !modal.classList.contains('show'));

  d.getElementById('resetAllBtn').click();
  modal.click();                                  // backdrop itself
  check('backdrop click cancels too', !modal.classList.contains('show') && g.app.state.briefAccepted === true);
  dom.window.close();

  // fallback A: programmatic confirm with no recent click -> native passes a true straight through
  const dom2 = makeDom({ beforeParse(window) { window.confirm = () => true; } });
  await sleep(120);
  check('native true passes through when no trigger is known', dom2.window.confirm('Programmatic question?') === true);
  dom2.window.close();

  // fallback B: swallowed (jsdom returns instantly) and no trigger -> press-again arming
  const dom3 = makeDom();
  const w3 = dom3.window, d3 = dom3.window.document;
  await sleep(120);
  check('swallowed + no trigger arms instead of approving', w3.confirm('Programmatic question?') === false);
  check('arming toast shown for the no-trigger fallback', /press the same button again/.test(d3.getElementById('toast').textContent));
  check('second programmatic call within the window is approved', w3.confirm('Programmatic question?') === true);
  dom3.window.close();
}

/* ---------- 16. studio opens below the fold: scroll + toast on the transition ---------- */
{
  console.log('\n[16] open-studio transition scrolls the stage into view');
  const dom = makeDom({ beforeParse(window) {
    window.Element.prototype.scrollIntoView = function () { (window.__scrolls = window.__scrolls || []).push(this.id || this.className || '?'); };
  } });
  const w = dom.window, d = w.document, g = w.__guide;
  await sleep(120);
  w.answer('boss', 'acceptBrief');
  w.answer('artist', 'placeholderArt');
  w.answer('scientist', 'rescueMotion');
  w.answer('scientist', 'rescueMomentum');
  w.answer('programmer', 'makeBehavior');
  g.app.state.tabLeft = 'brief'; w.renderAll();
  w.__scrolls = [];
  d.querySelector('[data-open-studio]').click();
  await sleep(150);
  check('studio opened', g.app.state.studioOpen === true);
  check('stage scrolled into view on the transition', (w.__scrolls || []).includes('stageWrap'));
  check('transition toast points below the fold', /studio floor is open/.test(d.getElementById('toast').textContent));
  g.app.state.tabLeft = 'brief'; w.renderAll();
  w.__scrolls = [];
  d.querySelector('[data-open-studio]').click();
  await sleep(150);
  check('re-click when already open does not scroll again', !(w.__scrolls || []).includes('stageWrap'));
  dom.window.close();
}

/* ---------- summary ---------- */
console.log('\n==============================');
console.log(`PASS ${pass}  FAIL ${fail}`);
if (failures.length) { console.log('failures:'); failures.forEach(f => console.log('  - ' + f)); process.exit(1); }
process.exit(0);
