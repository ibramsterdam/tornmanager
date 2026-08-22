# Recruiter

A Torn userscript for company recruiting, part of the TornManager monorepo
(it previously lived in the standalone `torn-recruiter` repo, merged here with
history). Since 0.5.0 it is a thin client over the TornManager server, which
fetches and refreshes all game data. It finds high working-stat players employed in chosen company types and shows whether they are online right now. No server: all data and API keys stay in the browser, everything talks directly to `api.torn.com/v2`.

## How it works

The TornManager server runs a daily pipeline (roster snapshots, a Hall of Fame
working-stats sweep, and a per-player backfill) and serves the results through
`/api/recruiter/matches`. The userscript posts the filters, renders the page of
matches, and polls `/api/recruiter/status` for the online state of the visible
companies (served from a 5-minute server cache). Player factions come along in
the roster, so matches flag employees who share a faction with their company
director. The admin pipeline overview lives at `/admin/recruiter`.

## Sign in and subscription

The script is locked behind a TornManager account and subscription, reusing the existing server endpoints (`POST /api/session`, `POST /api/subscription`). Sign-in mirrors the TornManager auth screen (animated banner, key disclosure table, agree checkbox) and only accepts Public access keys. Without an active subscription the overlay shows the subscription screen (Xanax to Bram [2728237], 1 week per Xanax, "Check for new payments"). Subscription status is rechecked in the background at most every 6 hours. The Privacy Policy and Terms of Service are embedded in the extension itself, and the panel footer mirrors TornManager: signed-in name with profile link, legal links, Copy debug info, version.

## API keys

The Keys screen contributes keys to a shared pool stored on the TornManager
server (`/api/recruiter/submit_key`, validated server-side: Public access only,
one key per owner). The server uses the pool for its background fetching; every
call carries `comment=tmrecruiter` so key owners can audit usage in their Torn
key log. Revoking a key on the Keys screen stops all use of it.

## Development

```
cd userscripts/tm-recruiter
npm install
npm run dev     # watch build, install dist/recruiter.user.js from disk in your userscript manager
npm run build
npm run release # build + copy to userscript/tm-recruiter.user.js at the repo root
```

To cut a versioned release, use `bin/publish tm-recruiter [patch|minor|major|x.y.z]`
from the repo root — it bumps the version, rebuilds, and stages the artifact.

The overlay is reachable from the injected sidebar icon (blue R) and the account dropdown menu entry, same pattern as TornManager.

## Distribution

Public install link — the built script committed at `userscript/tm-recruiter.user.js`:

    https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-recruiter.user.js

Installed scripts auto-update from that same URL (`@updateURL`/`@downloadURL`)
whenever the committed file's `@version` increases. Access is gated by the
TornManager subscription server-side, so a visible install link gives away
nothing.
