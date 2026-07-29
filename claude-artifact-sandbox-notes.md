# Claude Artifact Sandbox — Field Notes

Hard-won, empirically verified behaviors of apps running as claude.ai artifacts.
Established July 2026 while porting Microsoft Comic Chat, tested on Windows
desktop Chrome and the Claude Android app. Add this file to a Claude Project so
every conversation starts already knowing it. Behaviors are host-dependent and
may change; each entry says what was observed, not what documentation claims.

## Getting files OUT of an artifact

1. **Never use `download` on a `data:` URL.** Android Chrome blocks it outright.
   Use `canvas.toBlob(...)` → `URL.createObjectURL(blob)` → anchor click. This
   works on desktop.
2. **On the Claude Android app, even blob downloads are broken**: a save dialog
   appears, the user picks a name, and the file never lands anywhere findable.
   Suppress the download attempt on Android (`/Android/i.test(navigator.userAgent)`)
   to avoid the false promise.
3. **The Web Share API is Android's working export channel**:
   `navigator.share({files:[new File([blob], name, {type})]})` after a
   `navigator.canShare` check. Opens the system share sheet (save to Photos,
   Drive, message, etc.).
4. Always give the user an in-page rendering of the output too (an overlay with
   the image), since right-click (desktop) / long-press (Android) context menus
   are the fallback of last resort. Use a **blob URL for the `<img>` src**, not a
   data URL — some WebViews only offer the context menu for blob-backed images.

## Getting files IN

5. **A static `<input type=file hidden>` clicked programmatically never opens a
   picker in the app WebView.** A dynamically created, never-attached input does:

   ```js
   const inp = document.createElement("input");
   inp.type = "file"; inp.accept = ".json";
   inp.onchange = () => { /* read inp.files[0] */ };
   inp.click();   // no appendChild needed — and hidden attributes break it
   ```

6. **Drag-and-drop works on desktop only** (no such gesture on mobile).
7. **Cross-origin fetch is blocked by the artifact CSP** — even from
   CORS-permissive hosts like GitHub Pages. The only network path is the
   keyless `fetch("https://api.anthropic.com/v1/messages", ...)`.
8. **Paste is size-limited on Android**: the clipboard rides binder IPC with a
   hard 1 MB transaction buffer, and text is UTF-16 in the parcel — so the
   practical ceiling is roughly 400 KB of characters per copy. Larger payloads
   must be transferred in sequential chunks, with the app accumulating until a
   parse succeeds. Watch `input` events, not just `paste` events — Gboard's
   clipboard chip inserts text without firing `paste`. Also strip Chrome's
   share-selection decoration (curly quotes + appended source URL).
9. **The most reliable way to ship large assets is inside the HTML itself**:
   gzip + base64 the asset, decompress at boot with
   `new Response(blob.stream().pipeThrough(new DecompressionStream("gzip"))).text()`.

## Publishing

10. **Artifact publishing has an undocumented size cap.** Observed: 917 KB
    accepted; 1.56 MB and 2.28 MB rejected ("File is too large"). Budget ~950 KB
    total. If the asset doesn't fit, embed a partial set and provide an upgrade
    path.
11. **Republishing keeps the same origin**, so localStorage persists across
    artifact versions — old saved state (including old schema bugs) survives
    upgrades. Version your storage format.

## Storage

12. **localStorage works and persists in artifacts** (contrary to official
    guidance that it fails). Quota is tight though: compress before storing
    (`CompressionStream("gzip")` + base64 ≈ removes the base64 overhead of
    embedded PNG data), wrap every access in try/catch, and tell the user
    honestly whether the write succeeded.

## Dialogs, styling, feedback

13. **`confirm()`, `alert()`, `prompt()` silently no-op** (sandbox lacks
    `allow-modals`): they return falsy without displaying anything. Build DOM
    modals. Any `if (confirm(...))` branch is dead code in an artifact.
14. **The `hidden` attribute loses to inline styles**: an element with inline
    `display:flex` stays visible when you set `.hidden = true`. Toggle
    `style.display` explicitly.
15. **Every permission-gated action needs guaranteed feedback.** Clipboard (and
    similar) promises can hang forever instead of rejecting when the iframe
    lacks the permission — race them with a timeout so the user always sees a
    success or failure message:

    ```js
    const withTimeout = (p, ms) => Promise.race([p,
      new Promise((_, rej) => setTimeout(() => rej(new Error("timeout")), ms))]);
    ```

## Clipboard specifics

16. **`navigator.clipboard` read AND write are denied to the artifact iframe on
    every platform** (no permission delegation) — verified on Windows desktop
    Chrome, not just mobile. Programmatic image copy is impossible; guide users
    to the right-click / long-press "Copy image" context menu instead.
17. Text copy has a fallback that works: put the text in a textarea, `.select()`
    it, and call `document.execCommand("copy")` within the user gesture.
18. When you do attempt clipboard/share APIs, **construct the payload
    synchronously inside the tap** — awaiting `toBlob` first can outlive the
    gesture's transient activation. `ClipboardItem` accepts a *promise* of a
    blob for exactly this reason.

## Keyboard & viewport (mobile)

19. **Viewport meta tags are inert inside the artifact iframe** — including
    `interactive-widget=resizes-content`. The host page owns the top-level
    viewport. `visualViewport` may also fail to report the keyboard.
20. The working pattern: **move the UI, not the keyboard**. On input focus
    (small screens), pin the input row `position:fixed; top:0` — the top of the
    screen is the one region the keyboard never covers. Exit the mode on send
    and on blur (delay the blur-restore ~300 ms so a tap on the Send button,
    which blurs first, still lands). **Never refocus the input after send on
    mobile** — it re-arms the mode and traps the user.

## Links & AI

21. **`target="_blank"` links open inside the Claude Android app**, not the
    system browser. Provide "Copy link" buttons (`clipboard.writeText` with the
    execCommand fallback) so users can open URLs in a real browser themselves.
22. **`window.claude.complete` no longer exists.** Use the keyless messages
    fetch. The artifact proxy allowlists model ids and can lag new releases —
    on a model-shaped error, retry once with a known-good fallback id so a
    model bump can never break every call.

## Fonts

23. Fonts named in SVG that gets serialized into `<img>` for canvas export must
    be **embedded as data-URI `@font-face` inside the serialized SVG** — the
    image context can't see page styles (system fonts do work). And canvas
    `measureText` never triggers `@font-face` loading on its own: call
    `document.fonts.load(...)` explicitly, then re-measure and re-render once.
    Keep measurement and rendering on the same font stack so layout is
    consistent per platform.
