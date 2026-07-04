#!/bin/sh
# Splice the voice-guide core + Piskel adapter into the pristine
# single-file app, before the DOCUMENT's </body>. NB: Piskel's
# data-uri export template embeds a nested </body> inside a
# text/template block, so we must splice at the LAST occurrence.
set -e
node - <<'NODE'
const fs = require('node:fs');
const app = fs.readFileSync('piskel-single.html', 'utf8');
const core = fs.readFileSync('vg-core.js', 'utf8');
const adapter = fs.readFileSync('piskel-adapter.js', 'utf8');
if (/VoiceGuide/.test(app)) throw new Error('app already contains a guide layer');
const i = app.lastIndexOf('</body>');
if (i < 0) throw new Error('no </body>');
const out = app.slice(0, i) +
  '<script>\n' + core + '</script>\n<script>\n' + adapter + '</script>\n' + app.slice(i);
if (!/<\/html>\s*$/.test(out) || out.indexOf('window.VoiceGuide=') < i - 1)
  throw new Error('splice landed in the wrong place');
fs.writeFileSync('piskel-guided.html', out);
console.log('piskel-guided.html bytes:', Buffer.byteLength(out));
NODE
