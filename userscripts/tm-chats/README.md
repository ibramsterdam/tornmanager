# Torn Manager Chats

The Tampermonkey chat userscript companion to TornManager (formerly the
all-in-one "Torn Manager" userscript). It talks to the Rails app's
JSON API (`/api/session`, `/api/subscription`, `/api/current_war`) — against
`http://localhost:3000` in development and `https://tornmanager.com` in production.

## Development Setup

1. Install dependencies:
   ```bash
   cd userscripts/tm-chats && npm install
   ```

2. Create a development wrapper script in Tampermonkey:
   ```javascript
   // ==UserScript==
   // @name         Torn Manager Dev (Local)
   // @require      file:///<path to repository>/userscripts/tm-chats/dist/development.tm-chats.user.js
   // @match        https://www.torn.com/*
   // @grant        GM.notification
   // @grant        GM.xmlHttpRequest
   // @grant        GM_addStyle
   // @run-at       document-start
   // ==/UserScript==
   ```
   Note: Update the `@require` path to match your local directory.

3. Start watch mode:
   ```bash
   npm run dev
   ```

4. Edit code → Save → Refresh browser to see changes

## Release

The public install link — opening it with Tampermonkey installed prompts to
install immediately — is the built script committed in this repo:

    https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-chats.user.js

Installed scripts auto-update from that same URL (`@updateURL`/`@downloadURL`)
whenever the committed file's `@version` increases.

The install URL is frozen: the source lives in `userscripts/tm-chats/`, but the
built artifact is always copied to `userscript/tm-chats.user.js` because every
installed script checks that exact path for updates. Do not move it.
(`userscript/tornmanager.user.js` and `userscript/package.json` are frozen
migration stubs for pre-0.4 installs of the old "Torn Manager" script — delete
them once the last old install has updated.)

```bash
cd userscripts/tm-chats
npm run release   # production build + copies dist/ to userscript/tm-chats.user.js
```

Then commit `userscript/tm-chats.user.js` and push. Bump the version in
`package.json` first — Tampermonkey only updates when `@version` increases —
and deploy the Rails app before pushing when the release depends on new API
endpoints. Never commit a dev build here (`npm run dev` writes a
localhost-flavored file to `dist/`; the release script always rebuilds for
production first).
