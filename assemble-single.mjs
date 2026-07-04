/* Assemble dest/prod into ONE self-contained piskel.html.
   Mechanical per kickoff: inline min.js into the boot loader's slot,
   inline the CSS with every url() asset converted to a data URI.
   The gif.ie.worker.js file is IE11-only (modern path already builds
   the worker from an inline Blob in min.js) — deliberately dropped. */
import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';

const PROD = 'dest/prod';
const html0 = readFileSync(join(PROD, 'index.html'), 'utf8');
const cssName = /css\/piskel-style-packaged(-[\d-]+)\.css/;
const jsName  = /js\/piskel-packaged-min(-[\d-]+)\.js/;
// version comes from the boot script
const ver = html0.match(/var version = "(-[\d-]+)"/)[1];
const cssPath = join(PROD, `css/piskel-style-packaged${ver}.css`);
const jsPath  = join(PROD, `js/piskel-packaged-min${ver}.js`);
let css = readFileSync(cssPath, 'utf8');
const js  = readFileSync(jsPath, 'utf8');

// sanity: nothing in the JS/CSS may terminate our inline tags early
for (const [name, text, bad] of [['min.js', js, /<\/script/i], ['css', css, /<\/style/i]]) {
  if (bad.test(text)) throw new Error(`${name} contains ${bad} — inline unsafe`);
}
if (/<!--/.test(js) && /<script/i.test(js))
  console.warn('min.js contains both <!-- and <script — check script-data escaping');

// inline every non-data url() in the CSS as a data URI, resolved from css/
const MIME = { png:'image/png', gif:'image/gif', svg:'image/svg+xml', woff:'font/woff',
  woff2:'font/woff2', ttf:'font/ttf', eot:'application/vnd.ms-fontobject', jpg:'image/jpeg' };
let missing = [];
const URLRE = /url\(\s*(['"]?)([^)'"]+)\1\s*\)/g;
// count uses; repeated assets (the icon spritesheets appear 37x each)
// become one :root custom property instead of N base64 copies
const uses = {};
for (const m of css.matchAll(URLRE)) if (!/^data:/.test(m[2])) uses[m[2]] = (uses[m[2]] || 0) + 1;
const vars = {}; let varDecls = '';
const toDataUri = ref => {
  const clean = ref.split(/[?#]/)[0];
  const ext = clean.split('.').pop().toLowerCase();
  const b64 = readFileSync(join(PROD, 'css', clean)).toString('base64'); // urls are relative to the css file
  return `url(data:${MIME[ext] || 'application/octet-stream'};base64,${b64})`;
};
css = css.replace(URLRE, (m, q, ref) => {
  if (/^data:/.test(ref)) return m;
  try {
    if (uses[ref] > 1) {
      if (!vars[ref]) {
        vars[ref] = '--pskl-asset-' + Object.keys(vars).length;
        varDecls += `${vars[ref]}:${toDataUri(ref)};`;
      }
      return `var(${vars[ref]})`;
    }
    return toDataUri(ref);
  } catch (e) { missing.push(ref); return m; }
});
if (varDecls) css = `:root{${varDecls}}\n` + css;
if (missing.length) console.warn('unresolved css assets:', missing);

let html = html0;
// 1. CSS: drop the runtime loadStyle call, park the style at end of head
const loadStyleLine = /^\s*loadStyle\("css\/piskel-style-packaged" \+ version \+ "\.css"\);\s*$/m;
if (!loadStyleLine.test(html)) throw new Error('loadStyle line not found');
html = html.replace(loadStyleLine, '  /* css inlined at assembly */');
html = html.replace('</head>', `<style id="piskel-inline-css">\n${css}\n</style>\n</head>`);

// 2. JS: drop the runtime loadScript call, inline the bundle right after
//    the boot script so _onPiskelReady sees a parsed DOM (end of body)
const loadScriptLine = /^\s*loadScript\("js\/piskel-packaged-min" \+ version \+ "\.js", "_onPiskelReady\(\)"\);\s*$/m;
if (!loadScriptLine.test(html)) throw new Error('loadScript line not found');
html = html.replace(loadScriptLine, '  /* js inlined at assembly */');
const bootEnd = html.indexOf('</script>', html.indexOf('var version = "'));
if (bootEnd < 0) throw new Error('boot script end not found');
const insertAt = bootEnd + '</script>'.length;
html = html.slice(0, insertAt) +
  `\n<script id="piskel-inline-js">\n${js}\n</script>\n<script>_onPiskelReady();</script>\n` +
  html.slice(insertAt);

writeFileSync('piskel-single.html', html);
console.log('piskel-single.html bytes:', Buffer.byteLength(html));
