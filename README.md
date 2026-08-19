# Recruiter

A standalone Torn userscript for company recruiting. It finds high working-stat players employed in chosen company types and shows whether they are online right now. No server: all data and API keys stay in the browser, everything talks directly to `api.torn.com/v2`.

## How it works

Three data layers, each refreshed by its own button in the overlay:

| layer | source | cost | cadence |
|---|---|---|---|
| Roster (who works where, ratings) | `/company/snapshot` + `/user/snapshot` CSVs | 2 calls | daily is plenty |
| Working stats | `/torn/hof?cat=workstats` paged to the configured floor | ~500 calls at a 400k floor (rank ~50,000) | every ~10 days |
| Status (online state, position, days) | `/company/{id}/employees` for companies containing matches | 1 call per company | on demand |

Calls are fired in bursts of 75 per key per minute instead of a 1/sec timer chain, so background tab throttling can't stall long fetches. Batches round-robin across the key pool and retry Torn's rate-limit error with backoff. The stats sweep persists its offset and resumes if interrupted.

## Sign in and subscription

The script is locked behind a TornManager account and subscription, reusing the existing server endpoints (`POST /api/session`, `POST /api/subscription`). Sign-in mirrors the TornManager auth screen (animated banner, key disclosure table, agree checkbox) and only accepts Public access keys. Without an active subscription the overlay shows the subscription screen (Xanax to Bram [2728237], 1 week per Xanax, "Check for new payments"). Subscription status is rechecked in the background at most every 6 hours. The Privacy Policy and Terms of Service are embedded in the extension itself, and the panel footer mirrors TornManager: signed-in name with profile link, legal links, Copy debug info, version.

## API keys

Torn's rate limit is 100 calls/min per player, not per key. The Keys screen therefore validates every added key (`/key/info` + `/user/basic`), accepts only Public access keys, and rejects keys whose owner is already in the pool. The sign-in key joins the pool automatically. More keys from different players means proportionally faster sweeps. Every call carries `comment=Recruiter` so key owners can audit usage in their Torn key log.

## Development

```
npm install
npm run dev     # watch build, install dist/recruiter.user.js from disk in your userscript manager
npm run build
npm run release # build + copy to recruiter.user.js in the repo root
```

The overlay is reachable from the injected sidebar icon (blue R) and the account dropdown menu entry, same pattern as TornManager.

## Distribution

Private. Create a secret gist containing `recruiter.user.js`, point `RELEASE_URL` in `vite.config.js` at the gist's raw URL, and rebuild so installs auto-update.

## Status

Scaffold. Working: overlay UI shell, sidebar icon + menu entry, key pool with owner validation, settings (types, star range, stats floor, inactivity cutoff), roster sync, HoF sweep, status refresh, results table with status filter.

Not built yet: shortlist and hide actions, per-company grouped view, response-shape verification against the live v2 API (`/key/info` access field, employees `position` shape), mobile layout, error surfacing beyond the progress line.
