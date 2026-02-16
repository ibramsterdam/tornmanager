# TornManager

A web-based tool for Torn.com players to track personal statistics, monitor progress, and manage subscriptions.

## AppSignal Dashboard Setup

Create a custom dashboard called **TornManager Overview** with the following charts:

### Row 1: Torn API Health

| Chart | Type | Metric | Notes |
|-------|------|--------|-------|
| API Response Time | Line graph | `torn_api.response_time` | Shows latency trends |
| API Requests | Line graph | `torn_api.requests` | Split by `status` tag (success/error) |
| Rate Limits & Invalid Keys | Counter/Bar | `torn_api.rate_limit` + `torn_api.invalid_key` | Alert-worthy events |

### Row 2: Authentication

| Chart | Type | Metric | Notes |
|-------|------|--------|-------|
| Logins | Line graph | `auth.login_success` + `auth.login_failed` | Two lines, different colors |
| Login Failures by Reason | Pie/Bar | `auth.login_failed` | Group by `reason` tag |

### Row 3: Subscriptions

| Chart | Type | Metric | Notes |
|-------|------|--------|-------|
| Xanax Payments | Counter/Line | `subscription.xanax_payment` | Payment tracking |
| Weeks Granted | Line graph | `subscription.weeks_granted` | Split by `type` tag |
| Faction Grants | Counter | `subscription.faction_grant` + `subscription.users_granted` | Bulk grants |
| Manual Refreshes | Counter/Line | `subscription.manual_refresh` + `subscription.refresh_failed` | User-triggered refreshes |

### Row 4: Jobs

| Chart | Type | Metric | Notes |
|-------|------|--------|-------|
| Personal Stats Jobs | Line graph | `jobs.personal_stats_fetched` vs `jobs.personal_stats_failed` | Job health |
