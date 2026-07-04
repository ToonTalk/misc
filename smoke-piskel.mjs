/* ============================================================
   smoke-piskel.mjs — headless smoke suite for piskel-guided.html
   (Piskel + voice-guide core + piskel-adapter).

   Run:   node smoke-piskel.mjs [path-to-piskel-guided.html]
   Deps:  npm install jsdom fake-indexeddb
          plus a canvas for jsdom: EITHER `npm install canvas`
          OR `npm install @napi-rs/canvas` (this suite detects the
          latter and writes a tiny node_modules/canvas shim that
          re-exports it — jsdom requires the package by name).
   Piskel boots fully headless with these shims (all in beforeParse):
   fake-indexeddb, matchMedia, ResizeObserver, URL.createObjectURL,
   Worker, scrollIntoView. The suite is deterministic: word speed 0,
   demo waits collapse, fetch is stubbed, no network.
   Exit code 0 iff FAIL 0. Run it twice; quote PASS twice.
   ============================================================ */
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
/* ---- canvas bootstrap: jsdom hard-requires the 'canvas' package ---- */
try { require.resolve('canvas'); }
catch (e) {
  try {
    const napi = dirname(require.resolve('@napi-rs/canvas/package.json'));
    const stub = join(dirname(napi), 'canvas');
    if (!existsSync(stub)) {
      mkdirSync(stub, { recursive: true });
      writeFileSync(join(stub, 'package.json'), JSON.stringify({ name: 'canvas', version: '0.0.0-napi-shim', main: 'index.js' }));
      writeFileSync(join(stub, 'index.js'), "module.exports = require('@napi-rs/canvas');\n");
    }
    console.log('[canvas: using @napi-rs/canvas via shim]');
  } catch (e2) { console.error('No canvas available: npm install canvas OR @napi-rs/canvas'); process.exit(2); }
}
const { JSDOM, VirtualConsole } = require('jsdom');

const HTML_PATH = process.argv[2] || new URL('./piskel-guided.html', import.meta.url).pathname;
const HTML = readFileSync(HTML_PATH, 'utf8');

let PASS = 0, FAIL = 0;
const check = (name, cond, note) => {
  if (cond) { PASS++; console.log('  ok  ' + name); }
  else { FAIL++; console.log('  FAIL ' + name + (note ? '  [' + note + ']' : '')); }
};
const sleep = ms => new Promise(r => setTimeout(r, ms));
const until = async (fn, ms = 5000, step = 100) => { const t0 = Date.now();
  while (Date.now() - t0 < ms) { if (fn()) return true; await sleep(step); } return fn(); };
setTimeout(() => { console.log('\nSUITE WATCHDOG FIRED — aborting.\nPASS ' + PASS + '  FAIL ' + (FAIL + 1)); process.exit(1); }, 180000);

const DOMS = [];
function makeDom(opts = {}) {
  const vc = new VirtualConsole();
  const errs = opts.collect || [];
  vc.on('jsdomError', e => { const s = String((e && e.message) || e);
    if (!/Not implemented|AudioContext|getContext/i.test(s)) errs.push(s.slice(0, 200)); });
  vc.on('error', (...a) => errs.push('console: ' + a.map(String).join(' ').slice(0, 200)));
  const dom = new JSDOM(HTML, {
    url: opts.url || 'https://localhost/', runScripts: 'dangerously', resources: 'usable',
    pretendToBeVisual: true, virtualConsole: vc,
    beforeParse(w) {
      const { indexedDB, IDBKeyRange } = require('fake-indexeddb');
      w.indexedDB = indexedDB; w.IDBKeyRange = IDBKeyRange;
      if (!w.matchMedia) w.matchMedia = q => ({ matches: false, media: q, addListener(){}, removeListener(){}, addEventListener(){}, removeEventListener(){} });
      w.ResizeObserver = class { observe(){} unobserve(){} disconnect(){} };
      if (!w.URL.createObjectURL) w.URL.createObjectURL = () => 'blob:x';
      w.Worker = class { constructor(){} postMessage(){} terminate(){} addEventListener(){} set onmessage(v){} };
      w.Element.prototype.scrollIntoView = function(){};
      if (opts.micBlocked) Object.defineProperty(w.document, 'permissionsPolicy',
        { value: { allowsFeature: f => f !== 'microphone' }, configurable: true });
      if (opts.slowConfirm) w.confirm = function () { const t = Date.now(); while (Date.now() - t < 200) {} return false; };
      if (opts.beforeParse) opts.beforeParse(w);
    }
  });
  DOMS.push(dom);
  return dom;
}
/* fetch stub: scripted responses, records every call */
function stubFetch(w, script) {
  const calls = [];
  w.fetch = async (url, init) => {
    const body = init && init.body ? JSON.parse(init.body) : null;
    calls.push({ url: String(url), headers: (init && init.headers) || {}, body });
    const r = script[Math.min(calls.length - 1, script.length - 1)];
    return { ok: r.ok !== false, status: r.status || 200, json: async () => r.json };
  };
  return calls;
}
const anthOK = text => ({ json: { content: [{ type: 'text', text }] } });

const __here = dirname(fileURLToPath(import.meta.url));

/* ================================================================
   [A] main instance: load, selectors, tour, provenance, gating,
       noAI, key UI + keyed providers, confirm tiers, takeover
   ================================================================ */
{
  console.log('\n[1] fresh load');
  const errs = [];
  const dom = makeDom({ collect: errs });
  const w = dom.window, d = w.document;
  await until(() => w.__guide && w.pskl && w.pskl.app && w.pskl.app.piskelController, 8000);
  await sleep(400);
  const G = w.__guide, PC = () => w.pskl.app.piskelController;
  const q = s => d.querySelector(s), qa = s => Array.from(d.querySelectorAll(s));

  check('piskel booted (controller, 1 frame)', !!PC() && PC().getFrameCount() === 1);
  check('guide hook exposed, idle', !!G && G.state === 'idle');
  check('panel present, open by default', !!q('#vgPanel') && d.body.classList.contains('vg-open'));
  check('greeting logged', q('#vgLog').children.length >= 1 && /Pixel Pal/.test(q('#vgLog').textContent));
  check('adapter key button injected into panel controls', !!q('#vgControls #vgKeyBtn'));
  check('no unexpected boot errors', errs.length === 0, errs.slice(0, 3).join(' | '));

  const L = G.layout;
  const coreCss = (q('#vgStyle') || {}).textContent || '';
  const appCss = (q('#vgAppStyle') || {}).textContent || '';
  check('layout config as designed', L.panelWidth === 300 && L.panelMargin === 302 && L.narrowMax === 700 && L.appBreakpoint === 0);
  check('core narrow bottom-dock rules emitted (config-derived)',
    coreCss.includes(`@media (max-width:${L.narrowMax}px`) && coreCss.includes(`margin-bottom:${L.panelMargin}px`) && coreCss.includes('translateY(102%)'));
  check('appBreakpoint 0 emits no mirror block', !coreCss.includes(`@media (max-width:${L.appBreakpoint + L.panelMargin}px`));
  check('adapter reflow moves the fixed app (config-derived)',
    appCss.includes(`body.vg-open .main-wrapper{right:${L.panelMargin}px}`) &&
    appCss.includes(`.right-sticky-section.sticky-section{right:${L.panelMargin}px}`) &&
    appCss.includes(`.expanded{right:${L.panelMargin + 280}px}`));
  check('adapter narrow rules lift the fixed app above the dock',
    appCss.includes(`@media (max-width:${L.narrowMax}px)`) && appCss.includes(`bottom:${L.panelMargin + 5}px`));

  d.getElementById('vgHide').click();
  await sleep(120);
  check('hide removes reflow class', !d.body.classList.contains('vg-open'));
  check("hide toast rides Piskel's own notifier, names the Guide tab",
    !!q('#user-message') && /Guide tab/.test(q('#user-message').textContent));
  check('restore tab labelled', /Guide/i.test((q('#vgTab') || {}).textContent || ''));
  d.getElementById('vgTab').click();
  await sleep(120);
  check('tab restores the panel', d.body.classList.contains('vg-open'));

  console.log('\n[2] selector cross-check (tour spots, SHOW targets, tool ids)');
  let spotsOK = true, bad = [];
  for (const st of G.steps) {
    if (!st.spot) continue;
    const r = typeof st.spot === 'function' ? st.spot() : q(st.spot);
    const n = Array.isArray(r) ? r.filter(Boolean).length : (r ? 1 : 0);
    if (!n) { spotsOK = false; bad.push(st.name); }
  }
  check('every tour spot resolves', spotsOK, bad.join(','));
  const app = G.app;
  bad = [];
  for (const t of app.SHOW_TARGETS) {
    await G.do({ verb: 'SHOW', args: t });
    if (!qa('.vg-spot').length) bad.push(t);
    G.unspot();
  }
  check('every SHOW target resolves and spotlights', bad.length === 0, bad.join(','));
  const openIcon = q('.right-sticky-section .tool-icon.has-expanded-drawer');
  if (openIcon) openIcon.click();                                  // close whatever drawer the loop left open
  await sleep(150);
  check('drawer closable after SHOW loop', !q('.right-sticky-section.expanded'));
  bad = Object.keys(app.TOOL_NAMES).filter(id => !q(`#tools-container [data-tool-id="${id}"]`));
  check('all 15 tool ids exist in the DOM', bad.length === 0, bad.join(','));

  console.log('\n[3] tour runs end to end');
  G.setWordMs(0);
  const fps0 = PC().getFPS();
  G.start();
  check('tour running', G.state === 'running');
  let sawSpot = false, sawMid = false;
  await until(() => { if (G.state === 'running' && G.cur >= 1) { sawMid = true; if (qa('.vg-spot').length) sawSpot = true; } return G.state === 'done'; }, 15000, 60);
  check('tour reaches done', G.state === 'done');
  check('mid-tour stops spotlight their targets', sawMid && sawSpot);
  check('speed demo restored the FPS', PC().getFPS() === fps0, String(PC().getFPS()));
  check('done status set', /pixels/i.test(q('#vgStatus').textContent));

  console.log('\n[4] provenance: player changes, one honest line');
  let base = G.snap();
  q('#preview-list .add-frame-action').click(); await sleep(120);
  let r = G.diff(base);
  check('frame add remarked', /added a frame/.test(r) && /carrying on/.test(r), r);
  base = G.snap();
  q('#tools-container [data-tool-id="tool-eraser"]').dispatchEvent(new w.MouseEvent('mousedown', { bubbles: true }));
  w.$.publish(w.Events.SELECT_PRIMARY_COLOR, ['#123456']);
  q('#preview-list .add-frame-action').click(); await sleep(120);
  r = G.diff(base);
  check('two-fact cap: frames + tool in, color out', /added a frame/.test(r) && /the eraser/.test(r) && !/color/.test(r), r);
  check('tools named in prose, ids kept off the tongue', !/tool-eraser/.test(r));
  base = G.snap();
  const tiles = () => qa('#preview-list .preview-tile');
  tiles()[2].querySelector('.delete-frame-action').click(); await sleep(120);
  r = G.diff(base);
  check('frame delete suppresses the forced frame-hop', /removed a frame/.test(r) && !/hopped/.test(r), r);
  base = G.snap();
  const notCur = PC().getCurrentFrameIndex() === 0 ? 2 : 1;
  await G.do({ verb: 'FRAME', args: 'SELECT ' + notCur }); await sleep(120);
  r = G.diff(base);
  check('frame-hop alone is worth a word', /hopped over to frame/.test(r), r);

  console.log('\n[5] pause / resume / skip / end');
  G.start(); await sleep(150);
  G.pauseCore();
  check('paused with a snapshot', G.state === 'paused' && !!G.pauseSnap);
  q('#preview-list .add-frame-action').click(); await sleep(120);
  const logN = q('#vgLog').children.length;
  G.resume(); await sleep(250);
  const resumeText = Array.from(q('#vgLog').children).slice(logN).map(e => e.textContent).join(' ');
  check('resume remark reports the player frame', /added a frame/.test(resumeText), resumeText.slice(0, 90));
  G.skip(); await sleep(120);
  check('skip advances while running', G.state === 'running');
  G.end(); await sleep(120);
  check('end stops the tour and clears the spotlight', G.state !== 'running' && qa('.vg-spot').length === 0);

  console.log('\n[6] DO gating: validate first, ratify second, point freely');
  const dlg = () => q('#vgConfirm') && q('#vgConfirm').classList.contains('show');
  const curDrawer = () => { const el = q('.tool-icon.has-expanded-drawer'); return el ? el.dataset.setting : null; };
  await G.do({ verb: 'DELETE_FRAME', args: '99' });
  check('invalid gated act is a silent no-op (no dialog)', !dlg());
  let frames = PC().getFrameCount();
  let p = G.do({ verb: 'DELETE_FRAME', args: String(frames) });
  await until(dlg, 2000, 40);
  check('valid gated act raises ratification', dlg() && /delete frame/.test(q('#vgConfirmMsg').textContent));
  q('#vgConfirmNo').click(); await p; await sleep(100);
  check('No leaves the state alone', PC().getFrameCount() === frames && !dlg());
  p = G.do({ verb: 'DELETE_FRAME', args: String(frames) });
  await until(dlg, 2000, 40); q('#vgConfirmYes').click(); await p; await sleep(150);
  check('Yes executes through the real control', PC().getFrameCount() === frames - 1);
  base = G.snap();
  p = G.do({ verb: 'RESIZE', args: '8 8' });
  await until(dlg, 2000, 40);
  check('resize ratification names the numbers', dlg() && /8 by 8/.test(q('#vgConfirmMsg').textContent));
  q('#vgConfirmYes').click(); await p;
  await until(() => PC().getWidth() === 8, 3000, 60);
  check('resize lands via the drawer form', PC().getWidth() === 8 && PC().getHeight() === 8);
  r = G.diff(base);
  check('resize remarked with dimensions', /resized the canvas to 8 by 8/.test(r), r);
  await G.do({ verb: 'TOOL', args: 'tool-pen' });
  await G.do({ verb: 'COLOR', args: '00ff00' });
  await G.do({ verb: 'FPS', args: '7' });
  await G.do({ verb: 'SHOW', args: 'export' }); await sleep(120);
  check('frictionless verbs never see a dialog', !dlg());
  check('TOOL / COLOR / FPS drove the real controls',
    w.pskl.app.toolController.currentSelectedTool.toolId === 'tool-pen' &&
    w.pskl.app.selectedColorsService.getPrimaryColor() === '#00ff00' && PC().getFPS() === 7);
  check('SHOW export opened the drawer', !!q('.right-sticky-section.expanded') && curDrawer() === 'export');
  await G.do({ verb: 'SHOW', args: 'export' });
  check('SHOW twice never toggles the drawer shut', !!q('.right-sticky-section.expanded'));
  q('[data-setting="export"]').click(); await sleep(120);

  await G.do({ verb: 'DELETE_LAYER', args: '' });
  check('DELETE_LAYER with one layer is a silent no-op', !dlg() && PC().getLayers().length === 1);
  await G.do({ verb: 'LAYER', args: 'ADD' }); await sleep(120);
  check('LAYER ADD lands and the list renders', PC().getLayers().length === 2 &&
    qa('[data-test-id="layer-item"]').length === 2);
  const name1 = PC().getCurrentLayer().getName();
  await G.do({ verb: 'LAYER', args: 'SELECT 2' }); await sleep(120);
  check('LAYER SELECT switches the current layer', PC().getCurrentLayer().getName() !== name1);
  await G.do({ verb: 'MERGE_LAYERS', args: '' });
  check('merge on the bottom layer is a silent no-op (button disabled)', !dlg() && PC().getLayers().length === 2);
  await G.do({ verb: 'LAYER', args: 'SELECT 1' }); await sleep(120);
  p = G.do({ verb: 'MERGE_LAYERS', args: '' });
  await until(dlg, 2000, 40);
  check('merge is gated and speaks plainly', dlg() && /squash/.test(q('#vgConfirmMsg').textContent));
  q('#vgConfirmYes').click(); await p; await sleep(150);
  check('merge lands via the real button', PC().getLayers().length === 1);
  await G.do({ verb: 'LAYER', args: 'ADD' }); await sleep(120);
  p = G.do({ verb: 'DELETE_LAYER', args: '' });
  await until(dlg, 2000, 40);
  check('layer delete is gated and names the layer', dlg() && /delete the layer called/.test(q('#vgConfirmMsg').textContent));
  q('#vgConfirmYes').click(); await p; await sleep(150);
  check('layer delete lands', PC().getLayers().length === 1);

  check('status text carries live facts', (() => { const s = app.statusText();
    return /Canvas: 8 by 8/.test(s) && /the pen \(tool-pen\)/.test(s) && /#00ff00/.test(s) && /7 FPS/.test(s); })(), app.statusText());

  console.log('\n[7] no key, no artifact: the honest no-AI steer');
  const calls0 = stubFetch(w, [anthOK('should never be called')]);
  const logN2 = q('#vgLog').children.length;
  await G.ask('what is a sprite?'); await sleep(200);
  const steer = Array.from(q('#vgLog').children).slice(logN2).map(e => e.textContent).join(' ');
  check('no network attempted', calls0.length === 0);
  check('steer points at the key button', /key button/.test(steer), steer.slice(0, 90));
  check('steer spotlights the key button', d.getElementById('vgKeyBtn').classList.contains('vg-spot'));
  G.unspot();

  console.log('\n[8] key UI + three keyed providers');
  d.getElementById('vgKeyBtn').click();
  check('key dialog opens', q('#vgKeyDlg').classList.contains('show'));
  check('three providers offered', qa('#vgKeyProv option').length === 3);
  q('#vgKeyProv').value = 'openai'; q('#vgKeyProv').dispatchEvent(new w.Event('change', { bubbles: true }));
  q('#vgKeyVal').value = 'sk-test-123';
  q('#vgKeySave').click(); await sleep(80);
  let cfg = JSON.parse(w.localStorage.getItem('piskel-guide-llm'));
  check('save writes provider, key and default model', cfg.provider === 'openai' && cfg.key === 'sk-test-123' && cfg.model === 'gpt-5.1');
  check('save confirmed in the transcript', /key saved/i.test(q('#vgLog').textContent));

  let calls = stubFetch(w, [{ json: { choices: [{ message: { content: 'A sprite is a small picture that moves.' } }] } }]);
  await G.ask('what is a sprite, really?');
  check('openai key routes to openai with Bearer auth', calls.length === 1 &&
    calls[0].url.startsWith('https://api.openai.com/v1/chat/completions') &&
    calls[0].headers.Authorization === 'Bearer sk-test-123' && calls[0].body.model === 'gpt-5.1' &&
    calls[0].body.messages[0].role === 'system');

  w.localStorage.setItem('piskel-guide-llm', JSON.stringify({ provider: 'google', key: 'g-key', model: 'gemini-3-flash' }));
  calls = stubFetch(w, [{ json: { candidates: [{ content: { parts: [{ text: 'Pixels are tiny squares.' }] } }] } }]);
  await G.ask('what is a pixel?');
  check('google key routes to gemini with key param + system_instruction', calls.length === 1 &&
    /^https:\/\/generativelanguage\.googleapis\.com\/v1beta\/models\/gemini-3-flash:generateContent\?key=g-key$/.test(calls[0].url) &&
    !!calls[0].body.system_instruction);

  w.localStorage.setItem('piskel-guide-llm', JSON.stringify({ provider: 'anthropic', key: 'a-key', model: 'claude-sonnet-4-6' }));
  calls = stubFetch(w, [anthOK('Frames are flipbook pages.')]);
  await G.ask('what is a frame?');
  check('anthropic key routes with x-api-key + browser-access header', calls.length === 1 &&
    calls[0].url === 'https://api.anthropic.com/v1/messages' &&
    calls[0].headers['x-api-key'] === 'a-key' &&
    calls[0].headers['anthropic-dangerous-direct-browser-access'] === 'true');
  w.localStorage.removeItem('piskel-guide-llm');

  console.log('\n[9] confirm wrapper, tier by tier');
  /* tier 1: recent trigger button -> in-page dialog with rule hint + escape hatch */
  const scratch = d.createElement('button');
  scratch.textContent = 'load demo';
  scratch.onclick = () => { w.__scratchRan = (w.__scratchRan || 0) + (w.confirm('This will erase your current piskel. Continue ?') ? 1 : 0); };
  d.body.appendChild(scratch);
  scratch.click(); await sleep(100);
  check('confirm with a known trigger becomes the in-page dialog', dlg() && /erase your current piskel/.test(q('#vgConfirmMsg').textContent));
  check('matched rule contributes its hint', /keep it, export it first/i.test(q('#vgConfirmHint').textContent));
  const extra = q('#vgConfirmExtra');
  check('escape hatch offered', extra && extra.style.display !== 'none' && /Export first/.test(extra.textContent));
  q('#vgConfirmYes').click(); await sleep(150);
  check('Yes re-triggers the handler and the native call passes', w.__scratchRan === 1);
  const scratch2 = d.createElement('button');
  scratch2.textContent = 'import demo';
  scratch2.onclick = () => { if (w.confirm('This will erase your current workspace. Continue ?')) w.__scratchRan++; };
  d.body.appendChild(scratch2);
  scratch2.click(); await sleep(100);
  check('second trigger raises its own dialog', dlg());
  q('#vgConfirmExtra').click(); await sleep(150);
  check('escape hatch opens the export drawer instead', !dlg() && w.__scratchRan === 1 && curDrawer() === 'export');
  q('[data-setting="export"]').click();
  /* tier 2: no recent trigger, native swallowed -> arm + press-again toast */
  await sleep(3100);                                   // fall outside the 3s trigger window
  const r1 = w.confirm('Delete palette ?');
  check('swallowed confirm returns false and arms', r1 === false &&
    /press the same button again/.test((q('#user-message') || {}).textContent || ''));
  const r2 = w.confirm('Delete palette ?');
  check('pressing again within the window passes', r2 === true);

  console.log('\n[10] takeover + shortcut hygiene');
  G.start(); await sleep(150);
  q('#drawing-canvas-container').dispatchEvent(new w.PointerEvent('pointerdown', { bubbles: true }));
  await sleep(120);
  check('synthetic pointerdown never pauses the tour (isTrusted takeover)', G.state === 'running');
  G.end();
  const toolBefore = w.pskl.app.toolController.currentSelectedTool.toolId;
  const inp = d.getElementById('vgIn'); inp.focus();
  inp.dispatchEvent(new w.KeyboardEvent('keydown', { key: 'e', keyCode: 69, which: 69, bubbles: true }));
  await sleep(80);
  check("typing in the guide's box never trips app shortcuts", w.pskl.app.toolController.currentSelectedTool.toolId === toolBefore);

  console.log('\n[11] composed prompts');
  const sys = G.system();
  check('system prompt teaches the exact DO: syntax', /DO: VERB ARGUMENTS/.test(sys) && /DO: SHOW place/.test(sys));
  check('binding table pairs every id with its visible name', /tool-eraser \(the eraser\)/.test(sys) && /tool-vertical-mirror-pen \(the mirror pen\)/.test(sys));
  check('canonical fragments composed in (status rule, consent scope, point-not-describe)',
    sys.includes('STATUS RIGHT NOW block') && sys.includes('authorize only the precise action') && /point/i.test(sys));
  check('gated verbs enumerated as visitor-asked-only', /Destructive verbs, allowed ONLY/.test(sys) && /DO: DELETE_FRAME n/.test(sys));

  dom.window.close();
}

/* ================================================================
   [B] artifact instance: keyless chain, prompt order, DO round
       trip, re-baseline, keyed-wins-in-artifact
   ================================================================ */
{
  console.log('\n[12] keyless Q&A inside a Claude artifact');
  const dom = makeDom({ url: 'https://abc123.claudeusercontent.com/' });
  const w = dom.window, d = w.document;
  await until(() => w.__guide && w.pskl && w.pskl.app, 8000); await sleep(400);
  const G = w.__guide, q = s => d.querySelector(s);
  G.setWordMs(0);
  check('artifact detected from hostname', G.inClaude === true);

  const calls = stubFetch(w, [
    { ok: false, status: 529, json: { error: { message: 'overloaded' } } },
    anthOK('Frames are the pages of your flipbook!\nDO: SHOW frames')
  ]);
  await G.ask('what are frames?'); await sleep(200);
  check('keyless goes straight to Anthropic, no key header', calls.length >= 1 &&
    calls[0].url === 'https://api.anthropic.com/v1/messages' && !('x-api-key' in calls[0].headers));
  check('model chain falls through on failure', calls.length === 2 &&
    calls[0].body.model === G.keylessModels[0] && calls[1].body.model === G.keylessModels[1]);
  const usr = calls[1].body.usr || calls[1].body.messages[0].content;
  check('user prompt ends with fresh status, then the question', (() => {
    const iS = usr.indexOf('STATUS RIGHT NOW'), iQ = usr.indexOf('what are frames?');
    return iS > -1 && iQ > iS && /Frames: \d/.test(usr.slice(iS, iQ)); })());
  const lastLog = q('#vgLog').lastChild.textContent;
  check('DO line stripped before speaking', /flipbook/.test(q('#vgLog').textContent) && !/DO:/.test(lastLog));
  check('DO: SHOW executed — frames spotlighted', q('#preview-list-wrapper').classList.contains('vg-spot'));
  G.unspot();

  console.log('\n[13] guide-driven acts re-baseline the pause snapshot');
  G.start(); await sleep(150);
  stubFetch(w, [anthOK('Here you go!\nDO: TOOL tool-eraser')]);
  await G.ask('switch me to the eraser'); await sleep(150);
  check('ask mid-tour pauses the tour', G.state === 'paused' && !!G.pauseSnap);
  check('guide DO re-baselined the snapshot (resume stays honest)', G.pauseSnap.tool === 'tool-eraser');
  const logN = q('#vgLog').children.length;
  G.resume(); await sleep(250);
  const resumeText = Array.from(q('#vgLog').children).slice(logN).map(e => e.textContent).join(' ');
  check('resume remark silent about the guide-driven switch', !/eraser/.test(resumeText), resumeText.slice(0, 80));
  G.end();

  console.log('\n[14] a configured key wins even inside the artifact');
  w.localStorage.setItem('piskel-guide-llm', JSON.stringify({ provider: 'openai', key: 'sk-art', model: 'gpt-5.1' }));
  const calls2 = stubFetch(w, [{ json: { choices: [{ message: { content: 'Hi!' } }] } }]);
  await G.ask('hello?');
  check('keyed call routed to the configured provider', calls2.length === 1 && /api\.openai\.com/.test(calls2[0].url));
  dom.window.close();
}

/* ================================================================
   [C] artifact + mic policy blocked
   ================================================================ */
{
  console.log('\n[15] microphone blocked by policy (artifact sandbox)');
  const dom = makeDom({ url: 'https://abc123.claudeusercontent.com/', micBlocked: true });
  const w = dom.window, d = w.document;
  await until(() => w.__guide, 8000); await sleep(300);
  const G = w.__guide, q = s => d.querySelector(s);
  G.setWordMs(0);
  check('policy block detected, listening off', G.micPolicyBlocked === true);
  check('greeting steers to typing', /type/i.test(q('#vgLog').textContent));
  d.getElementById('vgMic').click(); await sleep(200);
  check('mic click explains and mentions the key-button route',
    /key button at the top of my panel/.test(q('#vgLog').textContent));
  dom.window.close();
}

/* ================================================================
   [D] slow native confirm = a human pressed Cancel
   ================================================================ */
{
  console.log('\n[16] confirm tier 3: slow native cancel is respected');
  const dom = makeDom({ slowConfirm: true });
  const w = dom.window, d = w.document;
  await until(() => w.__guide, 8000); await sleep(300);
  const r1 = w.confirm('This will erase your current piskel. Continue ?');
  const r2 = w.confirm('This will erase your current piskel. Continue ?');
  check('slow false is a human Cancel: no arming, no nagging', r1 === false && r2 === false &&
    !/press the same button again/.test((d.querySelector('#user-message') || {}).textContent || ''));
  dom.window.close();
}

/* ================================================================
   [E] every inline script block parses standalone
   ================================================================ */
{
  console.log('\n[17] node --check every inline script block');
  const blocks = [];
  const re = /<script(?![^>]*\bsrc=)([^>]*)>([\s\S]*?)<\/script>/gi;
  let m; while ((m = re.exec(HTML))) {
    const attrs = m[1] || '';
    if (/type\s*=\s*["'](?!(text\/javascript|module))/i.test(attrs)) continue;  // templates etc.
    if (m[2].trim()) blocks.push(m[2]);
  }
  let ok = 0, failNote = '';
  for (let i = 0; i < blocks.length; i++) {
    const f = join(tmpdir(), 'vg-block-' + i + '.js');
    writeFileSync(f, blocks[i]);
    try { execFileSync(process.execPath, ['--check', f], { stdio: 'pipe' }); ok++; }
    catch (e) { failNote = 'block ' + i + ': ' + String(e.stderr).slice(0, 120); }
  }
  check('all ' + blocks.length + ' executable script blocks parse', ok === blocks.length, failNote);
  check('guide layer present exactly once', (HTML.match(/window\.VoiceGuide=/g) || []).length === 1 &&
    HTML.lastIndexOf('window.VoiceGuide=') > HTML.indexOf('_onPiskelReady'));
}

console.log('\n==============================');
console.log('PASS ' + PASS + '  FAIL ' + FAIL);
DOMS.forEach(dm => { try { dm.window.close(); } catch (e) {} });
process.exit(FAIL ? 1 : 0);
