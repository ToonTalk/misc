/* ============================================================
   piskel-adapter.js — Piskel adapter for the voice-guide core.
   Adapter #2 (first external field test of the doc). Audience:
   kids and beginners. Everything app-named lives here; the
   machinery is vg-core.js. Spliced after vg-core.js, below the
   app — drives Piskel only through its real controls and its
   own event bus ($.publish is Piskel's public control surface,
   one level down from the buttons that publish the same events).
   ============================================================ */
let api;                          // assigned by VoiceGuide.create; closures resolve at call time
const F = VoiceGuide.fragments;
const qs = s => document.querySelector(s);
const qsa = s => Array.from(document.querySelectorAll(s));
const PC = () => window.pskl.app.piskelController;
const PANEL_W = 300, PANEL_M = 302;

/* ---------- tool id <-> visible name (one home: feeds the tour,
   the system-prompt binding table, provenance wording, and
   normalizeReply) ---------- */
const TOOL_NAMES = {
  'tool-pen': 'the pen', 'tool-vertical-mirror-pen': 'the mirror pen',
  'tool-paint-bucket': 'the paint bucket', 'tool-colorswap': 'the color swapper',
  'tool-eraser': 'the eraser', 'tool-stroke': 'the line tool',
  'tool-rectangle': 'the rectangle', 'tool-circle': 'the circle',
  'tool-move': 'the move tool', 'tool-shape-select': 'the shape picker',
  'tool-rectangle-select': 'the box select', 'tool-lasso-select': 'the lasso',
  'tool-lighten': 'the lighten tool', 'tool-dithering': 'the dither tool',
  'tool-colorpicker': 'the color picker'
};
const toolId = s => { s = String(s || '').toLowerCase(); if (!s) return null;
  if (TOOL_NAMES[s]) return s; if (TOOL_NAMES['tool-' + s]) return 'tool-' + s; return null; };
const toolName = id => TOOL_NAMES[id] || id;
const curToolId = () => { try { return window.pskl.app.toolController.currentSelectedTool.toolId; } catch (e) { return ''; } };

/* ---------- adapter stylesheet ----------
   Piskel's .main-wrapper and right column are position:fixed, so
   core's body-margin reflow cannot move them (doc finding: the
   reflowCSS seam has no unconditioned slot; injected here instead).
   Also: core palette vars mapped to Piskel's gray+gold, the confirm
   dialog styled like Piskel's gold-bordered dialogs, and the key
   dialog. Kept in one <style id="vgAppStyle"> so the suite can
   assert it against the layout constants. */
{
  const st = document.createElement('style');
  st.id = 'vgAppStyle';
  st.textContent = [
':root{--panel:#252525;--ink:#e8e8e8;--accent:#ffd700;--muted:#9a9a9a;--line:rgba(255,255,255,.18);--gold:gold}',
'#vgMain,#vgGo{background:linear-gradient(180deg,#ffe27a,#e0af1f);color:#1d1d1d}',
'/* always-on reflow for a fixed-position app */',
`body.vg-open .main-wrapper{right:${PANEL_M}px}`,
`body.vg-open .right-sticky-section.sticky-section{right:${PANEL_M}px}`,
`body.vg-open .right-sticky-section.sticky-section.expanded{right:${PANEL_M + 280}px}`,
`body.vg-open #dialog-container-wrapper{right:${PANEL_M}px;padding:40px 60px}`,
'/* narrow: core bottom-docks the panel; lift the fixed app above it */',
`@media (max-width:700px){`,
`  body.vg-open .main-wrapper{right:0;bottom:${PANEL_M + 5}px}`,
`  body.vg-open .right-sticky-section.sticky-section{right:0;bottom:${PANEL_M}px}`,
`  body.vg-open .right-sticky-section.sticky-section.expanded{right:280px}`,
`  body.vg-open #dialog-container-wrapper{right:0;bottom:${PANEL_M}px}`,
'}',
'/* confirm + key dialogs, dressed like Piskel dialogs */',
'.vg-pk-modal{background:#2f2f2f;border:2px solid gold;border-radius:4px;padding:16px 18px;max-width:430px;',
'  color:#e8e8e8;font-size:13px;line-height:1.5;box-shadow:0 10px 40px rgba(0,0,0,.65);font-family:Arial}',
'.vg-pk-modal h2{margin:0 0 8px;font-size:15px;color:gold}',
'.vg-pk-row{display:flex;gap:8px;justify-content:flex-end;margin-top:8px}',
'.vg-pk-yes{background:gold;color:#1d1d1d;border:none;border-radius:3px;padding:7px 13px;font-weight:700;cursor:pointer}',
'.vg-pk-no{background:#3d3d3d;color:#e8e8e8;border:1px solid #555;border-radius:3px;padding:7px 13px;cursor:pointer}',
'#vgKeyDlg{position:fixed;inset:0;display:none;align-items:center;justify-content:center;background:rgba(0,0,0,.55);z-index:10002}',
'#vgKeyDlg.show{display:flex}',
'#vgKeyDlg label{display:block;margin:8px 0 3px;color:#bbb;font-size:12px}',
'#vgKeyDlg select,#vgKeyDlg input{width:100%;box-sizing:border-box;background:#1d1d1d;color:#e8e8e8;',
'  border:1px solid #555;border-radius:3px;padding:6px 8px;font-size:13px}'
  ].join('\n');
  document.head.appendChild(st);
}

/* ---------- LLM: keyless in artifacts; a configured key always
   wins, on the user's own provider (Anthropic / OpenAI / Google) ---------- */
const LLM_STORE = 'piskel-guide-llm';
function llmConfig(){ try { return JSON.parse(localStorage.getItem(LLM_STORE) || 'null') || {}; } catch (e) { return {}; } }
const PROVIDERS = {
  anthropic: { label: 'Anthropic (Claude)', model: 'claude-sonnet-4-6',
    async call(cfg, sys, usr){
      const res = await fetch('https://api.anthropic.com/v1/messages', { method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-api-key': cfg.key,
          'anthropic-version': '2023-06-01', 'anthropic-dangerous-direct-browser-access': 'true' },
        body: JSON.stringify({ model: cfg.model, max_tokens: 1000, system: sys, messages: [{ role: 'user', content: usr }] }) });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error((data.error && data.error.message) || ('HTTP ' + res.status));
      return (data.content || []).map(c => c.text || '').join('\n').trim();
    } },
  openai: { label: 'OpenAI', model: 'gpt-5.1',
    async call(cfg, sys, usr){
      const res = await fetch('https://api.openai.com/v1/chat/completions', { method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + cfg.key },
        body: JSON.stringify({ model: cfg.model, messages: [{ role: 'system', content: sys }, { role: 'user', content: usr }] }) });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error((data.error && data.error.message) || ('HTTP ' + res.status));
      return (((data.choices || [])[0] || {}).message || {}).content ? data.choices[0].message.content.trim() : '';
    } },
  google: { label: 'Google (Gemini)', model: 'gemini-3.5-flash',
    async call(cfg, sys, usr){
      const res = await fetch('https://generativelanguage.googleapis.com/v1beta/models/' +
        encodeURIComponent(cfg.model) + ':generateContent?key=' + encodeURIComponent(cfg.key), { method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ system_instruction: { parts: [{ text: sys }] }, contents: [{ role: 'user', parts: [{ text: usr }] }] }) });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error((data.error && data.error.message) || ('HTTP ' + res.status));
      const cand = (data.candidates || [])[0];
      return (((cand || {}).content || {}).parts || []).map(p => p.text || '').join('').trim();
    } }
};

/* ---------- the tour ---------- */
const askPhrase = () => api.canListen ? 'press my microphone button and just ask'
  : 'type in the box at the bottom of my panel and just ask';
const setFpsControl = n => { const s = qs('#preview-fps'); if (!s) return;
  s.value = String(n); s.dispatchEvent(new Event('input', { bubbles: true })); s.dispatchEvent(new Event('change', { bubbles: true })); };

const STEPS = [
{ name: 'hello',
  text: () => "Hi! I'm Pixel Pal, and this is Piskel, where you make pixel art and little animations. I live in this panel and I never touch your drawing. Click anywhere to pause me, hide me with the arrow up top, and if you're curious about anything, " + askPhrase() + '.' },
{ name: 'canvas', spot: '#drawing-canvas-container',
  text: () => { let w = 32, h = 32; try { w = PC().getWidth(); h = PC().getHeight(); } catch (e) {}
    return 'This checkerboard is your canvas, and every little square is one pixel. Right now it is ' + w + ' pixels wide and ' + h + ' tall. Draw with the left mouse button, and roll the mouse wheel to zoom right in close.'; } },
{ name: 'tools', spot: () => [qs('#tools-container'), qs('.pen-size-container')].filter(Boolean),
  text: 'Down the left side live your tools. The pen draws, the paint bucket fills a whole space at once, the eraser rubs out, and the mirror pen draws both halves of your picture at the same time, which feels like magic. Rest your mouse on any tool and a tip pops up with its keyboard shortcut. The four dots at the top set how chunky your pen is.' },
{ name: 'colors', spot: '.palette-wrapper',
  text: 'These two squares are your colors. The front one paints with the left mouse button, and the back one paints with the right button, so you always carry two colors at once. The tiny arrows swap them over.' },
{ name: 'frames', spot: '#preview-list-wrapper',
  text: () => { let n = 1; try { n = PC().getFrameCount(); } catch (e) {}
    return 'This strip holds your frames, which are the pages of your flipbook. You have ' + n + ' right now. Press the plus tile to add one, rest your mouse on a frame for copy and delete buttons, and drag frames up and down to shuffle their order.'; } },
{ name: 'preview', spot: () => [qs('#animated-preview-canvas-container'), qs('#onion-skin-toggle-button')].filter(Boolean),
  text: 'Up here your flipbook actually plays, round and round. The little onion button is onion skin: it shows a ghost of the frame before, so you can line your next drawing up with it.' },
{ name: 'speed', spot: () => [qs('#preview-fps'), qs('#display-fps')].filter(Boolean), during: true,
  text: 'This slider is the speed: how many frames flash past every second. Watch the little preview while I wiggle it. Slow... then fast... and back to where you had it.',
  action: async g => { let was = 12; try { was = PC().getFPS(); } catch (e) {}
    try { await api.wait(api.demoMs(1200), g); setFpsControl(2);
      await api.wait(api.demoMs(1600), g); setFpsControl(24);
      await api.wait(api.demoMs(1600), g); setFpsControl(was);
    } finally { try { if (PC().getFPS() !== was) setFpsControl(was); } catch (e) {} } } },
{ name: 'layers', spot: '.layers-list-container',
  text: 'Layers are sheets of see-through paper stacked on top of each other. Draw your hero on the top sheet and the background underneath, and you can fix one without smudging the other. These buttons add layers, shuffle them, and squash them together.' },
{ name: 'palettes', spot: '.palettes-list-container',
  text: 'A palette is a little box of colors you want to keep together. Piskel starts you off with some famous ones. Try them from this list, or press Create to build your very own.' },
{ name: 'transform', spot: () => { const l = qs('.transformations-show-more-link'); return l && l.closest('.toolbox-container'); },
  text: 'These are the transform tools. They work on the whole picture in one go: flip it over, spin it round, or nudge it into the middle.' },
{ name: 'resize-save', spot: () => [qs('[data-setting="resize"]'), qs('[data-setting="save"]')].filter(Boolean),
  text: 'On the right edge, Resize changes how many pixels your canvas has, and Save tucks your work into this browser. To keep a drawing really safe, or carry it to another computer, use Export to make a dot piskel file. That one never gets lost.' },
{ name: 'export', spot: '[data-setting="export"]',
  text: 'And Export is how your art leaves Piskel: a P N G picture, a moving GIF, or a sprite sheet for a game. When your animation is ready, that button is your move. I point at things, but the big moments are all yours.' },
{ name: 'wrap', spot: () => [document.getElementById('vgMic'), document.getElementById('vgIn')].filter(Boolean),
  text: () => "That's the tour! Now it's your turn: pick the pen, grab a color, and make your first pixels. I'm right here if you get stuck. If you ever wonder how something works, " + askPhrase() + '.' }
];

/* ---------- provenance: snapshot + one spoken line of what the
   PLAYER changed. Frame-and-layer grain by design; pixels are out
   of scope. Suppression: frame-hopping is a forced side effect of
   adding or deleting frames, so it is only reported alone; the
   two-fact cap keeps remarks short. ---------- */
function snapshot(){
  const s = { frames: 1, layers: 1, fps: 12, w: 32, h: 32, frameIndex: 0, tool: curToolId(), color: '#000000' };
  try { const pc = PC();
    s.frames = pc.getFrameCount(); s.layers = pc.getLayers().length; s.fps = pc.getFPS();
    s.w = pc.getWidth(); s.h = pc.getHeight(); s.frameIndex = pc.getCurrentFrameIndex();
  } catch (e) {}
  try { s.color = window.pskl.app.selectedColorsService.getPrimaryColor(); } catch (e) {}
  return s;
}
function diffRemark(o){
  if (!o) return '';
  const n = snapshot(), facts = [];
  if (n.w !== o.w || n.h !== o.h) facts.push('resized the canvas to ' + n.w + ' by ' + n.h);
  if (n.frames > o.frames) facts.push('added ' + (n.frames - o.frames === 1 ? 'a frame' : (n.frames - o.frames) + ' frames'));
  else if (n.frames < o.frames) facts.push('removed ' + (o.frames - n.frames === 1 ? 'a frame' : (o.frames - n.frames) + ' frames'));
  if (n.layers > o.layers) facts.push('added a new layer');
  else if (n.layers < o.layers) facts.push('squashed your layers down to ' + n.layers);
  if (n.tool && n.tool !== o.tool) facts.push('switched to ' + toolName(n.tool));
  if (n.color !== o.color) facts.push('picked a new color');
  if (n.fps !== o.fps) facts.push('set the speed to ' + n.fps + ' frames a second');
  if (!facts.length && n.frameIndex !== o.frameIndex)            // minor facet, only when nothing bigger
    facts.push('hopped over to frame ' + (n.frameIndex + 1));
  if (!facts.length) return '';
  return 'You ' + facts.slice(0, 2).join(' and ') + ' — carrying on!';
}

/* ---------- Q&A grounding ---------- */
function systemPrompt(ctx){
  return 'You are Pixel Pal, the friendly spoken guide who lives in a side panel of Piskel, a free pixel-art and animation editor the visitor is using right now. The visitor may be a child or a beginner: use warm, simple, concrete words and short sentences, and never invent features. ' +
  (ctx.tourLive ? 'You are mid-tour, at the stop called ' + ctx.stopName + '. ' : '') +
  'How Piskel works, exactly and completely: the checkerboard canvas in the middle is the drawing, one square per pixel; tools are picked by pressing their icons in the left column, and every tool tooltip shows its keyboard shortcut; the left mouse button draws with the primary color, the right button with the secondary color, and the two color squares at the bottom left swap with the tiny arrows; the strip beside the canvas holds the animation frames — the plus tile adds a frame, resting the mouse on a tile reveals duplicate and delete buttons, and dragging tiles reorders them, which is the ONLY drag and drop in the whole app; the animated preview at the top right plays the animation at the speed set by the FPS slider under it, sliding it to zero stops the animation, and there is no separate play or pause button; the layers box below stacks see-through drawing sheets with buttons to add, reorder, merge and delete; the saved palettes box below that holds reusable color sets; the transform tools flip, rotate or center the whole picture; the icons on the right edge open drawers for Resize, Save to this browser, Export as P N G, GIF, sprite sheet or dot piskel file, and Import; control Z undoes nearly anything. ' +
  F.selfKnowledge + ' ' + F.voiceRules + ' ' + F.statusRule +
  ' You can also act on the app, only by ending your reply with a single DO line, its own last line, in the exact form: DO: VERB ARGUMENTS (the colon matters). The verbs, with every id bound to its visible name: ' +
  'DO: SHOW place — point at and scroll to a place; place is one of canvas, tools, colors, frames, preview, speed, layers, palettes, transform, resize, save, export, import, ask (ask means my own microphone and typing box). ' +
  'DO: TOOL id — pick a drawing tool; id must be one of: ' + Object.keys(TOOL_NAMES).map(k => k + ' (' + TOOL_NAMES[k] + ')').join(', ') + '. ' +
  'DO: COLOR hex — set the primary color, like DO: COLOR #ff0000. ' +
  'DO: FPS n — set the preview speed, zero to twenty four. ' +
  'DO: FRAME ADD, DO: FRAME DUPLICATE, or DO: FRAME SELECT n — add, copy, or jump to a frame (n counts from one at the top of the strip). ' +
  'DO: LAYER ADD or DO: LAYER SELECT n — add a layer or pick one (n counts from one at the top of the list). ' +
  'Destructive verbs, allowed ONLY when the visitor clearly asked for that exact thing: DO: DELETE_FRAME n, DO: DELETE_LAYER, DO: MERGE_LAYERS, DO: RESIZE width height. ' + F.ratifyNotice + ' ' +
  F.doLineMeta + ' In prose always call tools by their visible names, like the pen or the eraser, never the ids, and your prose must agree with the id on the DO line. ' +
  F.consentScope({ pointExample: 'show the frame strip', escalations: 'deleting frames, merging layers, or resizing the canvas', safeVerb: 'SHOW' }) + ' ' +
  F.pointNotDescribe({ pointVerbs: 'DO: SHOW' });
}
function statusText(){
  const s = snapshot();
  let layerName = ''; try { layerName = PC().getCurrentLayer().getName(); } catch (e) {}
  let secondary = ''; try { secondary = window.pskl.app.selectedColorsService.getSecondaryColor(); } catch (e) {}
  const unsaved = /\*\s*$/.test((qs('.piskel-name') || {}).textContent || '');
  const drawer = qs('.right-sticky-section.expanded')
    ? 'open on ' + ((qs('.right-sticky-section .tool-icon.has-expanded-drawer') || {}).dataset || {}).setting : 'closed';
  return 'Canvas: ' + s.w + ' by ' + s.h + ' pixels. Frames: ' + s.frames + ', viewing frame ' + (s.frameIndex + 1) + '. ' +
    'Layers: ' + s.layers + (layerName ? ', current layer ' + layerName : '') + '. ' +
    'Tool: ' + toolName(s.tool) + ' (' + s.tool + '). Primary color ' + s.color + (secondary ? ', secondary ' + secondary : '') + '. ' +
    'Preview speed: ' + s.fps + ' FPS. Unsaved changes: ' + (unsaved ? 'yes' : 'no') + '. Settings drawer: ' + drawer + '.';
}

/* ---------- SHOW targets ---------- */
function openDrawer(setting){
  const icon = qs('[data-setting="' + setting + '"]');
  if (!icon) return null;
  const alreadyThis = icon.classList.contains('has-expanded-drawer') &&
    qs('.right-sticky-section') && qs('.right-sticky-section').classList.contains('expanded');
  if (!alreadyThis) icon.click();                 // real control; guarded so SHOW twice never closes it
  return qs('#drawer-container') || icon;
}
const SHOW_TARGETS = {
  canvas: () => qs('#drawing-canvas-container'),
  tools: () => [qs('#tools-container'), qs('.pen-size-container')].filter(Boolean),
  colors: () => qs('.palette-wrapper'),
  frames: () => qs('#preview-list-wrapper'),
  preview: () => qs('#animated-preview-canvas-container'),
  speed: () => [qs('#preview-fps'), qs('#display-fps')].filter(Boolean),
  layers: () => qs('.layers-list-container'),
  palettes: () => qs('.palettes-list-container'),
  transform: () => { const l = qs('.transformations-show-more-link'); return l && l.closest('.toolbox-container'); },
  resize: () => openDrawer('resize'),
  save: () => openDrawer('save'),
  export: () => openDrawer('export'),
  import: () => openDrawer('import'),
  ask: () => [document.getElementById('vgMic'), document.getElementById('vgIn')].filter(Boolean)
};

/* ---------- DO verb table. Core policy: validate BEFORE any
   dialog; gated verbs are prompt-gated AND player-ratified;
   pointing stays frictionless. ---------- */
const frameTile = n => qsa('#preview-list .preview-tile')[n - 1] || null;
const VERBS = {
  SHOW: { exec(p){ const f = SHOW_TARGETS[(p[0] || '').toLowerCase()]; if (f) api.spot(() => f()); } },
  TOOL: {
    validate(p){ const id = toolId(p[0]); return id ? { id } : null; },
    exec(p, a, ctx){ const el = qs('#tools-container [data-tool-id="' + ctx.id + '"]');
      if (el){ el.dispatchEvent(new MouseEvent('mousedown', { bubbles: true })); api.spot(() => el); } }
  },
  COLOR: {
    validate(p){ const m = /^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{3})$/.exec(p[0] || ''); return m ? { hex: '#' + m[1].toLowerCase() } : null; },
    exec(p, a, ctx){ window.$.publish(window.Events.SELECT_PRIMARY_COLOR, [ctx.hex]); api.spot(() => qs('.palette-wrapper')); }
  },
  FPS: {
    validate(p){ const n = parseInt(p[0], 10); return Number.isInteger(n) && n >= 0 && n <= 24 ? { n } : null; },
    exec(p, a, ctx){ setFpsControl(ctx.n); api.spot(() => [qs('#preview-fps'), qs('#display-fps')].filter(Boolean)); }
  },
  FRAME: {
    validate(p){ const op = (p[0] || '').toUpperCase();
      if (op === 'ADD' || op === 'DUPLICATE') return { op };
      if (op === 'SELECT'){ const n = parseInt(p[1], 10);
        return Number.isInteger(n) && n >= 1 && n <= PC().getFrameCount() ? { op, n } : null; }
      return null; },
    exec(p, a, ctx){
      if (ctx.op === 'ADD'){ const b = qs('#preview-list .add-frame-action'); if (b) b.click(); }
      else if (ctx.op === 'DUPLICATE'){ const t = frameTile(PC().getCurrentFrameIndex() + 1);
        const b = t && t.querySelector('.duplicate-frame-action'); if (b) b.click(); }
      else if (ctx.op === 'SELECT'){ const t = frameTile(ctx.n);
        const c = t && (t.querySelector('.tile-view') || t); if (c) c.click(); }
      api.spot(() => qs('#preview-list-wrapper'));
    }
  },
  LAYER: {
    validate(p){ const op = (p[0] || '').toUpperCase();
      if (op === 'ADD') return { op };
      if (op === 'SELECT'){ const n = parseInt(p[1], 10);
        return Number.isInteger(n) && n >= 1 && n <= qsa('[data-test-id="layer-item"]').length ? { op, n } : null; }
      return null; },
    exec(p, a, ctx){
      if (ctx.op === 'ADD'){ const b = qs('[data-test-id="layer-add-button"]'); if (b) b.click(); }
      else { const it = qsa('[data-test-id="layer-item"]')[ctx.n - 1];
        const nm = it && it.querySelector('.layer-name'); if (nm) nm.click(); else if (it) it.click(); }
      api.spot(() => qs('.layers-list-container'));
    }
  },
  DELETE_FRAME: {
    gated: true,
    validate(p){ const total = PC().getFrameCount(); if (total <= 1) return null;
      const n = p[0] ? parseInt(p[0], 10) : PC().getCurrentFrameIndex() + 1;
      return Number.isInteger(n) && n >= 1 && n <= total ? { n } : null; },
    ratifyText(p, ctx){ return 'The guide wants to delete frame ' + ctx.n + '. Undo can bring it back — OK?'; },
    exec(p, a, ctx){ const t = frameTile(ctx.n);
      const b = t && t.querySelector('.delete-frame-action'); if (b) b.click();
      api.spot(() => qs('#preview-list-wrapper')); }
  },
  DELETE_LAYER: {
    gated: true,
    validate(){ try { return PC().getLayers().length > 1 && !qs('[data-test-id="layer-delete-button"]').disabled ? {} : null; } catch (e) { return null; } },
    ratifyText(){ let nm = 'this layer'; try { nm = PC().getCurrentLayer().getName(); } catch (e) {}
      return 'The guide wants to delete the layer called ' + nm + '. Undo can bring it back — OK?'; },
    exec(){ const b = qs('[data-test-id="layer-delete-button"]'); if (b) b.click(); api.spot(() => qs('.layers-list-container')); }
  },
  MERGE_LAYERS: {
    gated: true,
    validate(){ try { return PC().getLayers().length > 1 && !qs('[data-test-id="layer-merge-button"]').disabled ? {} : null; } catch (e) { return null; } },
    ratifyText(){ return 'The guide wants to squash the current layer into the one below it. Undo can split them again — OK?'; },
    exec(){ const b = qs('[data-test-id="layer-merge-button"]'); if (b) b.click(); api.spot(() => qs('.layers-list-container')); }
  },
  RESIZE: {
    gated: true,
    validate(p){ const w = parseInt(p[0], 10), h = parseInt(p[1], 10);
      return Number.isInteger(w) && Number.isInteger(h) && w >= 1 && h >= 1 && w <= 1024 && h <= 1024 ? { w, h } : null; },
    ratifyText(p, ctx){ return 'The guide wants to resize the whole drawing to ' + ctx.w + ' by ' + ctx.h + ' pixels. Anything outside gets snipped off (Undo works) — OK?'; },
    exec(p, a, ctx){
      openDrawer('resize');
      const box = qs('.resize-canvas'); if (!box) return;
      const wi = box.querySelector('[name="resize-width"]'), hi = box.querySelector('[name="resize-height"]');
      const form = box.querySelector('form'); if (!wi || !hi || !form) return;
      const ratio = box.querySelector('.resize-ratio-checkbox');   // keep-ratio would fight explicit w/h
      if (ratio && ratio.checked) ratio.click();
      wi.value = String(ctx.w); wi.dispatchEvent(new Event('input', { bubbles: true })); wi.dispatchEvent(new Event('change', { bubbles: true }));
      hi.value = String(ctx.h); hi.dispatchEvent(new Event('input', { bubbles: true })); hi.dispatchEvent(new Event('change', { bubbles: true }));
      hi.value = String(ctx.h);                                    // re-assert in case a ratio handler rewrote it
      form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
      api.spot(() => qs('#drawing-canvas-container'));
    }
  }
};

/* ---------- confirm rules (Piskel uses window.confirm a lot;
   destructive overwrites get an Export escape hatch) ---------- */
const CONFIRM_RULES = [
  { match: /erase your current (piskel|workspace)/i,
    hint: 'This replaces the drawing on your canvas. If you want to keep it, export it first.',
    extraLabel: 'Export first', onExtra(a){
      /* defer past the in-flight click: Piskel's body-click handler
         closes an expanded drawer on any outside click, and the extra
         button's own click is still bubbling when this runs */
      setTimeout(() => openDrawer('export'), 0); a.notify('Export your drawing, then try again.'); } },
  { match: /already a piskel saved as .* Overwrite/i,
    hint: 'This writes over the copy saved in this browser.',
    extraLabel: 'Export first', onExtra(a){
      /* defer past the in-flight click: Piskel's body-click handler
         closes an expanded drawer on any outside click, and the extra
         button's own click is still bubbling when this runs */
      setTimeout(() => openDrawer('export'), 0); a.notify('Export your drawing, then try again.'); } },
  { match: /delete palette/i, hint: "The palette's colors go away — your drawing stays." },
  { match: /delete this session/i, hint: 'That backup will be gone for good.' },
  { match: /Replace all custom shortcuts/i, hint: 'Your keyboard shortcuts go back to normal.' }
];

/* ---------- key dialog (adapter UI: Piskel has no LLM plumbing
   of its own, so the guide carries a small three-provider setup) ---------- */
function buildKeyDialog(){
  const d = document.createElement('div');
  d.id = 'vgKeyDlg';
  d.innerHTML = '<div class="vg-pk-modal" style="width:330px"><h2>Live AI setup</h2>' +
    '<p style="margin:0 0 4px">Inside a Claude artifact I answer on my own. Anywhere else, add a key from your grown-up:</p>' +
    '<label>Provider</label><select id="vgKeyProv"></select>' +
    '<label>API key</label><input id="vgKeyVal" type="password" spellcheck="false" placeholder="paste key, or leave empty to clear">' +
    '<label>Model</label><input id="vgKeyModel" spellcheck="false">' +
    '<div class="vg-pk-row"><button id="vgKeySave" class="vg-pk-yes">Save</button>' +
    '<button id="vgKeyCancel" class="vg-pk-no">Cancel</button></div></div>';
  document.body.appendChild(d);
  const prov = d.querySelector('#vgKeyProv');
  Object.keys(PROVIDERS).forEach(k => { const o = document.createElement('option');
    o.value = k; o.textContent = PROVIDERS[k].label; prov.appendChild(o); });
  prov.onchange = () => { d.querySelector('#vgKeyModel').value = PROVIDERS[prov.value].model; };
  d.addEventListener('click', e => { if (e.target === d) d.classList.remove('show'); });
  d.querySelector('#vgKeyCancel').onclick = () => d.classList.remove('show');
  d.querySelector('#vgKeySave').onclick = () => {
    const key = d.querySelector('#vgKeyVal').value.trim();
    const cfg = key ? { provider: prov.value, key, model: d.querySelector('#vgKeyModel').value.trim() || PROVIDERS[prov.value].model } : {};
    try { localStorage.setItem(LLM_STORE, JSON.stringify(cfg)); } catch (e) {}
    d.classList.remove('show');
    api.logAdd(key ? 'Live AI key saved — questions now use ' + PROVIDERS[cfg.provider].label + '.' : 'Live AI key cleared.');
  };
  return d;
}
function openKeyDialog(){
  const d = document.getElementById('vgKeyDlg') || buildKeyDialog();
  const cfg = llmConfig();
  const prov = d.querySelector('#vgKeyProv');
  prov.value = cfg.provider || 'anthropic';
  d.querySelector('#vgKeyVal').value = cfg.key || '';
  d.querySelector('#vgKeyModel').value = cfg.model || PROVIDERS[prov.value].model;
  d.classList.add('show');
}

/* ---------- create ---------- */
api = VoiceGuide.create({
  id: 'piskel',
  ui: {
    title: 'Pixel Pal', ariaLabel: 'Pixel Pal voice guide', mascot: '\u{1F47E}', thinkFace: '\u{1F914}',
    tabLabel: 'Guide', tabTitle: 'Bring Pixel Pal back',
    askPlaceholder: 'Ask about pixel art\u2026',
    greeting: canListen => "Hi, I'm Pixel Pal! Press the play button for a tour of Piskel, or " +
      (canListen ? 'press the microphone' : 'type below') + ' and ask me anything about pixel art.',
    hideToast: 'Pixel Pal is tucked away — the Guide tab on the edge brings me back.',
    doneStatus: "Tour's done — go make pixels! Ask me anything anytime.",
    notify(text){ try { window.$.publish(window.Events.SHOW_NOTIFICATION, [{ content: text }]);
      setTimeout(() => { try { window.$.publish(window.Events.HIDE_NOTIFICATION); } catch (e) {} }, 5000);
    } catch (e) {} },
    modal: { backdrop: 'vg-pk-backdrop', modal: 'vg-pk-modal', row: 'vg-pk-row', yes: 'vg-pk-yes', no: 'vg-pk-no' }
  },
  layout: { panelWidth: PANEL_W, panelMargin: PANEL_M, narrowMax: 700, appBreakpoint: 0 },
  takeover: { events: ['pointerdown'] },        // Piskel is shortcut-heavy: keydown must never auto-pause
  tour: { steps: STEPS },
  provenance: { snapshot, diffRemark },
  prompts: { system: systemPrompt, status: statusText },
  llm: {
    hasKey(){ const c = llmConfig(); return !!(c.key && PROVIDERS[c.provider]); },
    keyedCall(sys, usr){ const c = llmConfig();
      return PROVIDERS[c.provider].call({ provider: c.provider, key: c.key, model: c.model || PROVIDERS[c.provider].model }, sys, usr); },
    normalizeReply(t){ return String(t).replace(/\btool-[a-z][a-z-]*\b/g, m => TOOL_NAMES[m] ? TOOL_NAMES[m].replace(/^the /, 'the ') : m); },
    noAI: { spot: () => document.getElementById('vgKeyBtn'),
      say: "I can't reach a live A I from here without a key. Press the little key button at the top of my panel and ask a grown-up to help set one up — or open this page as a Claude artifact, where I can answer on my own." }
  },
  verbs: VERBS,
  confirmRules: CONFIRM_RULES,
  strings: { micKeyHint: ', via the little key button at the top of my panel.' },
  testHook: { app(){ return { pskl: window.pskl, Events: window.Events, llmConfig, TOOL_NAMES,
    PROVIDERS: Object.keys(PROVIDERS), snapshot, statusText, SHOW_TARGETS: Object.keys(SHOW_TARGETS) }; } },
  init(a){
    /* key button: adapter UI appended to the core panel (judgment
       call — Piskel has no settings surface of its own to host it) */
    const btn = document.createElement('button');
    btn.id = 'vgKeyBtn'; btn.className = 'vg-btn'; btn.title = 'Live AI setup (API key)';
    btn.textContent = '\u{1F511}';
    btn.onclick = openKeyDialog;
    const controls = document.getElementById('vgControls');
    if (controls) controls.insertBefore(btn, document.getElementById('vgSkip'));
    /* Piskel recomputes its drawing area via ResizeObserver, but a
       few popups measure on window resize; nudge them when the
       panel opens or closes. */
    let lastOpen = document.body.classList.contains('vg-open');
    new MutationObserver(() => {
      const open = document.body.classList.contains('vg-open');
      if (open !== lastOpen){ lastOpen = open;
        setTimeout(() => { try { window.dispatchEvent(new Event('resize')); } catch (e) {} }, 300); }
    }).observe(document.body, { attributes: true, attributeFilter: ['class'] });
  }
});
