# Torn Manager Userscript

The Tampermonkey userscript companion to TornManager. It talks to the Rails app's
JSON API (`/api/session`, `/api/subscription`, `/api/current_war`) — against
`http://localhost:3000` in development and `https://tornmanager.com` in production.

## Development Setup

1. Install dependencies:
   ```bash
   cd userscript && npm install
   ```

2. Create a development wrapper script in Tampermonkey:
   ```javascript
   // ==UserScript==
   // @name         Torn Manager Dev (Local)
   // @require      file:///<path to repository>/userscript/dist/development.tornmanager.user.js
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

Releases are published as GitHub release assets. The public install link —
open it in a browser with Tampermonkey and it prompts to install — is always:

    https://github.com/ibramsterdam/tornmanager/releases/latest/download/tornmanager.user.js

Installed scripts auto-update from that same URL (`@updateURL`/`@downloadURL`).

```bash
cd userscript && npm run build   # outputs dist/tornmanager.user.js
gh release create userscript-v$(node -p "require('./package.json').version") \
  dist/tornmanager.user.js --title "Userscript v$(node -p "require('./package.json').version")"
```

Deploy the Rails app first when the release depends on new API endpoints —
Tampermonkey rolls the update out to everyone within a day.
