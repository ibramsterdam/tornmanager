# AGENTS.md

Instructions for AI agents working on TornManager.

## Critical Rules

- **NEVER commit and push without explicit user consent.** Always show the diff and ask before committing. Only push when the user says "commit and push" or similar.
- **NEVER run destructive git commands** (`push --force`, `reset --hard`, `rebase`) without explicit approval.
- **NEVER run kamal deployments ever**
- If you are unsure about something, stop and ask. Do not guess.
- Write code like DHH would
- Ideally use Test driven development coding style

## Project Overview

TornManager is a Rails 8 management and analytics tool for the game [Torn City](https://www.torn.com). It integrates with the Torn API and TornStats API to provide faction leaders with member tracking, ranked war analytics, stat backfills, and compliance monitoring.

## Tech Stack

| Component        | Technology                                      |
|------------------|-------------------------------------------------|
| Language         | Ruby 3.3.5                                      |
| Framework        | Rails 8.1                                       |
| Database         | SQLite3 (4 databases: primary, cache, queue, cable) |
| Job Backend      | Solid Queue (database-backed, runs inside Puma)  |
| Cache Backend    | Solid Cache                                     |
| WebSocket        | Solid Cable (Action Cable)                      |
| Asset Pipeline   | Propshaft                                       |
| JavaScript       | Importmap + Hotwire (Turbo + Stimulus)          |
| Web Server       | Puma + Thruster                                 |
| Auth             | Custom cookie-based sessions with bcrypt        |
| Monitoring       | AppSignal                                       |
| Deployment       | Kamal to single server (Docker, amd64)          |
| CI               | GitHub Actions                                  |

No Redis, no PostgreSQL, no Node.js build step. This is a "Solid trifecta" Rails 8 app.

## Key Architecture Decisions

### Job Queues (Solid Queue)

Configured in `config/queue.yml`. Four named queues:

- **`admin`** (1 thread, 1.1s polling) -- Jobs using the app owner's personal API key. Rate-limited to ~28 req/min. Base class: `AdminApiJob`. Credentials via `AdminCredentials.api_key`.
- **`faction`** (5 threads, 0.5s polling) -- Faction-level jobs using each faction's own API key. `limits_concurrency` ensures one API call per faction at a time while allowing parallel execution across factions. Base class: `FactionApiJob`.
- **`war`** (3 threads, 0.5s polling) -- Real-time war status polling.
- **`default`** (3 threads, 0.1s polling) -- Orchestrator jobs, scheduled cleanup, and non-API work.

Each Torn API key has independent rate limits. Jobs using different API keys can run in parallel. Use `limits_concurrency` for per-key/per-faction rate limiting rather than serializing an entire queue.

Solid Queue runs in-process with Puma (`SOLID_QUEUE_IN_PUMA=true`), not as a separate worker.

### Torn API Integration

API wrapper models live in `app/models/torn_api/` with sub-modules for different API categories (Faction, User, Torn, Key, Market). Each API call includes a ~1 second sleep to respect rate limits.

### Multi-Database

Four SQLite databases, each with their own migrations directory:
- `primary` -- application data
- `cache` -- Solid Cache
- `queue` -- Solid Queue
- `cable` -- Solid Cable

## Development Commands

```bash
mise exec -- bin/rails server          # Start dev server (also runs Solid Queue)
mise exec -- bin/rails test            # Run full test suite (always run all tests)
mise exec -- bin/rails test:system     # Run system tests (Capybara + Selenium)
mise exec -- bin/rubocop               # Lint (rubocop-rails-omakase style)
mise exec -- bin/brakeman --no-pager   # Security scan
mise exec -- bin/bundler-audit         # Gem vulnerability scan
mise exec -- bin/importmap audit       # JS dependency audit
```

## Testing

- **Run tests**: `mise exec -- bin/rails test`
- **Always run the full suite** after making changes. The suite is fast (~4 seconds) so there's no reason to run individual test files.
- **Framework**: Minitest with Mocha for mocking
- **Fixtures**: Used for test data (`test/fixtures/`)
- **Parallelization**: Enabled (`parallelize(workers: :number_of_processors)`)
- **Session helper**: `sign_in_as(user)` and `sign_out` available in integration tests via `SessionTestHelper`

## CI Pipeline

Five parallel jobs on every push to `main` and every PR:

1. `scan_ruby` -- Brakeman + bundler-audit
2. `scan_js` -- importmap audit
3. `lint` -- RuboCop with GitHub formatter
4. `test` -- `bin/rails db:test:prepare test`
5. `system-test` -- `bin/rails db:test:prepare test:system`

All CI jobs must pass. If you introduce changes, verify they won't break lint or tests.

## Code Style

- **Ruby**: rubocop-rails-omakase (Rails team's opinionated defaults). No custom overrides.
- **No conventional commits**: Commit messages are plain English, lowercase or capitalized, imperative style. Examples: "Fix sign in button disappearing on hover", "Add data coverage card and 3-column settings layout".
- **Guard clauses**: Preferred over nested conditionals. `return if/unless` is idiomatic, but do not use `return` as the last statement in a method (Rubocop will flag it).

## Directory Structure (Key Paths)

```
app/
  controllers/
    admin/              # Admin namespace
    api/                # JSON API namespace
    factions/           # Faction sub-controllers (leadership, wars, polling)
    concerns/           # FactionAccess concern for authorization
  models/
    torn_api/           # Torn API wrapper models
    torn_stats_api/     # TornStats API wrapper
    torn/               # Torn game data models (Item, Stock)
  jobs/
    daily/              # Scheduled daily jobs
  services/             # Service objects (minimal -- mostly ComplianceSummary)
  javascript/
    controllers/        # Stimulus controllers
  views/
    layouts/            # Application layouts
config/
  queue.yml             # Solid Queue configuration
  deploy.yml            # Kamal deployment config
test/
  fixtures/             # Test fixtures
  test_helpers/         # Custom test helpers
```
