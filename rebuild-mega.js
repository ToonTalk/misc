#!/usr/bin/env node
// rebuild-mega.js — reconstruction of the lost build-mega.js, derived from the built
// artifact itself. Two modes, exact inverses of each other:
//
//   node rebuild-mega.js extract  <mega.html> <outdir>
//       -> <outdir>/shell.html            (mega with each template body replaced by a marker)
//       -> <outdir>/apps/<name>.html      (each template's exact byte content)
//   node rebuild-mega.js assemble <outdir> <out-mega.html>
//       -> splices apps back into shell.html markers
//   node rebuild-mega.js roundtrip <mega.html>
//       -> extract to tmp, assemble, byte-compare against the input. PASS/FAIL.
//
// Properties:
// - Structure-driven (scans for <template id="tpl-...">), no hardcoded offsets, so it
//   works on any build of the mega as long as apps live in id="tpl-*" templates.
// - Byte-exact: template bodies are spliced verbatim, including leading/trailing
//   whitespace. `roundtrip` is the gate: run it on the CURRENT mega before trusting
//   anything; only a byte-identical result licenses using extract's outputs as
//   canonical sources.
// - The bridge script and any artifact patches inside each template are treated as
//   part of the app (they are feature-detected/inert standalone per the technical
//   report), so extracted apps are complete, runnable, canonical files.

'use strict';
const fs = require('fs');
const path = require('path');

const OPEN_RE = /<template\s+id="tpl-([a-zA-Z0-9_-]+)"\s*>/g;
const CLOSE = '</template>';
const marker = (name) => `<!--TM:APP ${name}-->`;

function extractParts(megaText) {
  // sanity: every <template must have exactly one matching </template>, and no
  // template body may itself contain the closing tag string.
  const opens = [...megaText.matchAll(OPEN_RE)];
  const closeCount = megaText.split(CLOSE).length - 1;
  if (opens.length === 0) throw new Error('no <template id="tpl-..."> found');
  if (closeCount !== opens.length)
    throw new Error(`template open/close mismatch: ${opens.length} opens, ${closeCount} closes — a body may contain "${CLOSE}"; refusing`);
  const parts = [];
  for (const m of opens) {
    const bodyStart = m.index + m[0].length;
    const end = megaText.indexOf(CLOSE, bodyStart);
    if (end < 0) throw new Error(`unclosed template tpl-${m[1]}`);
    parts.push({ name: m[1], openTag: m[0], bodyStart, bodyEnd: end });
  }
  // ensure templates don't nest/overlap
  for (let i = 1; i < parts.length; i++)
    if (parts[i].openTag && parts[i - 1].bodyEnd > parts[i].bodyStart - parts[i].openTag.length)
      throw new Error('overlapping templates');
  return parts;
}

function extract(megaPath, outDir) {
  const mega = fs.readFileSync(megaPath, 'latin1'); // byte-faithful
  const parts = extractParts(mega);
  fs.mkdirSync(path.join(outDir, 'apps'), { recursive: true });
  let shell = '', cursor = 0;
  for (const p of parts) {
    const body = mega.slice(p.bodyStart, p.bodyEnd);
    fs.writeFileSync(path.join(outDir, 'apps', p.name + '.html'), body, 'latin1');
    shell += mega.slice(cursor, p.bodyStart) + marker(p.name);
    cursor = p.bodyEnd;
  }
  shell += mega.slice(cursor);
  fs.writeFileSync(path.join(outDir, 'shell.html'), shell, 'latin1');
  console.log(`extracted ${parts.length} apps: ${parts.map(p => p.name).join(', ')}`);
  return parts.map(p => p.name);
}

function assemble(dir, outPath) {
  let shell = fs.readFileSync(path.join(dir, 'shell.html'), 'latin1');
  const names = fs.readdirSync(path.join(dir, 'apps')).filter(f => f.endsWith('.html'));
  let used = 0;
  for (const f of names) {
    const name = f.replace(/\.html$/, '');
    const mk = marker(name);
    if (!shell.includes(mk)) { console.warn(`WARN: no marker for app "${name}" — skipped`); continue; }
    if (shell.split(mk).length !== 2) throw new Error(`marker for "${name}" not unique`);
    shell = shell.replace(mk, () => fs.readFileSync(path.join(dir, 'apps', f), 'latin1'));
    used++;
  }
  const leftover = shell.match(/<!--TM:APP [^>]*-->/);
  if (leftover) throw new Error(`unfilled marker remains: ${leftover[0]}`);
  fs.writeFileSync(outPath, shell, 'latin1');
  console.log(`assembled ${used} apps -> ${outPath} (${shell.length} bytes)`);
}

function roundtrip(megaPath) {
  const tmp = fs.mkdtempSync('/tmp/tm-rt-');
  extract(megaPath, tmp);
  const out = path.join(tmp, 'rebuilt.html');
  assemble(tmp, out);
  const a = fs.readFileSync(megaPath), b = fs.readFileSync(out);
  const ok = a.equals(b);
  console.log(ok ? `PASS  roundtrip byte-identical (${a.length} bytes)`
                 : `FAIL  differs: ${a.length} vs ${b.length} bytes`);
  process.exit(ok ? 0 : 1);
}

const [, , mode, ...args] = process.argv;
try {
  if (mode === 'extract') extract(args[0], args[1]);
  else if (mode === 'assemble') assemble(args[0], args[1]);
  else if (mode === 'roundtrip') roundtrip(args[0]);
  else { console.error('usage: rebuild-mega.js extract <mega> <dir> | assemble <dir> <mega> | roundtrip <mega>'); process.exit(2); }
} catch (e) { console.error('ERROR: ' + e.message); process.exit(1); }
