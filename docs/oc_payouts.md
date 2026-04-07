# Organized Crime Payouts

Feature suggestion from Woke [1457203] on 2026-04-07.

## The Problem

Factions running level 7-8 OCs use a rotation system where high-CPR members hop between OCs in the last day, filling critical roles to maximize completions. This pushes weekly completions from 3 to 6-7. The payout model is weekly and shared: everyone who participates gets a cut regardless of whether their specific OC succeeded. High-CPR members get a bonus split.

Torn's built-in OC payout is per-crime, which doesn't work for this rotation model.

## Desired Payout Model

- Weekly payout cycle
- Flat base split for all participants (e.g. 30-50m/week even if none of your OCs completed)
- Faction cut (% or flat) to cover OC item costs
- CPR-weighted bonus pool for high-skill members
- Ability to exclude members (e.g. low-skill members running level 5-6 OCs independently)

## What the API Provides

**Endpoint:** `/v2/faction/crimes` (faction API key required)

Per crime:
- Name, difficulty (5-8), status (Successful/Failed/Recruiting)
- Rewards: money, items, respect
- Timestamps: created, planning, executed, ready, expired

Per slot within a crime:
- Position name and ID (Engineer, Looter, Muscle, etc.)
- `checkpoint_pass_rate` (CPR) per member per slot
- User ID, joined_at timestamp, progress, outcome
- Item requirement: item ID, reusable flag, UID, whether consumed

**Endpoint:** `/v2/faction/{crimeId}/crime` for individual crime details

Supports `cat=completed` filter and pagination via `from`/`to` timestamps.

## Notes

- CPR is not a global stat per member. It's per-slot on each OC. We derive member CPR by averaging across their completed OCs.
- CPR increases over time as a member completes more crimes. Use recent CPR (not all-time average) for payout weighting. Tracking CPR over time could show member growth.
- Item sellback prices can come from the `/v2/torn/items` endpoint.
- Woke indicated willingness to pay "1 xan a week or 10 xan a month" for this feature.

---

## Implementation Plan

### Models

**`OrganizedCrime`** - Stores each OC from the API
- `faction_id` (FK)
- `torn_crime_id` (integer, unique per faction)
- `name` (string)
- `difficulty` (integer, 1-8)
- `status` (string: Successful, Failed, Expired, etc.)
- `money_reward` (bigint)
- `respect_reward` (integer)
- `created_at_torn` (datetime)
- `executed_at` (datetime)
- `ready_at` (datetime)
- Indexes: `[faction_id, torn_crime_id]` unique, `[faction_id, executed_at]`

**`OrganizedCrimeSlot`** - Each participant slot in an OC
- `organized_crime_id` (FK)
- `position` (string: Engineer, Looter, Muscle, etc.)
- `position_id` (string: P1, P2, etc.)
- `user_torn_id` (integer, nullable if unfilled)
- `checkpoint_pass_rate` (integer)
- `outcome` (string: Successful, Jailed, Injured, null)
- `joined_at` (datetime)
- `item_required_id` (integer, nullable)
- `item_reusable` (boolean)
- `item_consumed` (boolean, default false)
- Indexes: `[organized_crime_id]`, `[user_torn_id]`

**`OcPayoutGroup`** - Groups OCs for a weekly payout cycle
- `faction_id` (FK)
- `name` (string, e.g. "Week 14 - Apr 2026")
- `week_start` (date)
- `week_end` (date)
- `total_money` (bigint, sum of OC money rewards)
- `total_respect` (integer)
- `faction_cut_percent` (decimal)
- `cpr_bonus_percent` (decimal)
- `paid` (boolean, default false)
- `paid_at` (datetime, nullable)
- Indexes: `[faction_id, week_start]`

**`OcPayoutMember`** - Per-member payout within a group
- `oc_payout_group_id` (FK)
- `user_torn_id` (integer)
- `ocs_participated` (integer)
- `avg_cpr` (decimal)
- `base_payout` (bigint)
- `cpr_bonus` (bigint)
- `total_payout` (bigint)
- Indexes: `[oc_payout_group_id, user_torn_id]`

**`FactionSetting` additions** (existing model)
- `oc_payout_enabled` (boolean)
- `oc_min_difficulty` (integer, default 7, filter crimes below this)
- `oc_faction_cut_percent` (decimal, default 10)
- `oc_cpr_bonus_percent` (decimal, default 20)
- `oc_excluded_member_ids` (json, array of torn_ids to exclude)

### Routes

```
resource :organized_crimes, only: [:show], controller: "factions/leadership/organized_crimes" do
  post :sync
  post :create_payout_group
  patch :update_payout_group
  patch :mark_paid
end
```

All under `factions/:faction_torn_id/leadership/`.

### Sync Strategy

**`Daily::OrganizedCrimeSyncJob`** - Runs daily at 6am UTC
- Fetches `/v2/faction/crimes?cat=completed` paginating from the latest stored `executed_at`
- Upserts `OrganizedCrime` + `OrganizedCrimeSlot` records
- Uses `insert_all` with `unique_by` on `[faction_id, torn_crime_id]`

**`BackfillOrganizedCrimesJob`** - One-time, walks backwards like armory backfill
- Triggered on faction setup and from admin panel
- Fetches historical completed OCs

**`FetchOrganizedCrimesJob`** - Incremental fetcher (same pattern as `FetchArmoryNewsJob`)
- Extends `FactionApiJob` with rate limiting and concurrency control

No need to store active/recruiting OCs. Only completed (and failed) matter for payouts and CPR tracking.

### What to Show

**OC Overview Page** (`/factions/:id/leadership/organized_crimes`)

1. **CPR Leaderboard** - Table of members sorted by recent average CPR
   - Columns: Member, Avg CPR (last 30 days), OCs Completed, Roles (most common), CPR Trend (up/down)
   - Expandable rows showing per-OC CPR history

2. **Weekly OC Summary** - Grouped by week
   - Number of OCs completed/failed
   - Total money earned, total respect
   - Item costs (non-reusable items consumed x sellback price)
   - Net value (money - item costs)

3. **Payout Calculator** - For a selected week or date range
   - Configure: faction cut %, CPR bonus pool %, minimum difficulty
   - Exclude specific members
   - Shows per-member breakdown: base share, CPR bonus, total payout
   - "Mark as Paid" button
   - Export to clipboard (same pattern as ranked war payouts)

4. **OC History Table** - Scrollable list of all completed OCs
   - Columns: Name, Difficulty, Status, Money, Respect, Participants, Date
   - Expandable rows showing slot details with CPR per member

### Item Cost Calculation

For consumed non-reusable items, fetch sellback prices from `/v2/torn/items`. Cache item prices (they rarely change). Sum consumed item costs per OC and subtract from the reward pool before splitting.

### Payout Math

Given a payout group with total_money (after faction cut and item costs):

```
net_pool = total_money - (total_money * faction_cut_percent / 100) - item_costs
base_pool = net_pool * (1 - cpr_bonus_percent / 100)
bonus_pool = net_pool * cpr_bonus_percent / 100

# Base split: equal share for all participants
base_per_member = base_pool / participating_members.count

# CPR bonus: weighted by each member's average CPR
total_cpr = participating_members.sum(&:avg_cpr)
member_cpr_bonus = (member.avg_cpr / total_cpr) * bonus_pool

member_total = base_per_member + member_cpr_bonus
```
