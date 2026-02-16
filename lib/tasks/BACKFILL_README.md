# Backfill Stats Rake Tasks

## Overview

Four rake tasks are available for backfilling historical personal stats data from the Torn API for January 1-20, 2026.

## Recommended: Core Stats Backfill (Fast - 2.2 hours)

This backfills only the 7 core stats needed for your faction page.

### 1. Core Stats Dry Run

```bash
rails stats:backfill_2026_core_dry_run
```

### 2. Core Stats Backfill

```bash
rails stats:backfill_2026_core
```

**Stats Backfilled (7):**
- ✅ drugs_xanax (xantaken)
- ✅ other_refills_energy (refills)
- ✅ other_refills_nerve (nerverefills)
- ✅ other_merits_bought (meritsbought)
- ✅ items_used_boosters (boostersused)
- ✅ missions_missions (missionscompleted)
- ✅ other_activity_time (timeplayed)

**Estimated Time:**
- API calls: 26,600 (190 users × 20 days × 7 stats)
- Time: ~133 minutes (2.2 hours) at 0.3s per call

## Optional: Full Stats Backfill (Slow - 49 hours)

This backfills all 157 available stats (includes attacking, trading, travel, etc.).

### 3. Full Stats Dry Run

```bash
rails stats:backfill_2026_full_dry_run
```

### 4. Full Stats Backfill

```bash
rails stats:backfill_2026_full
```

**Stats Backfilled:**
- 157 out of 179 total attributes (87.7%)
- All attacking, trading, travel, drugs, missions, racing, etc.

**What CANNOT be backfilled (22 attributes):**
- Crime skills (13 attributes) - not available in API
- Item market stats (4 attributes) - not available in API  
- Other: attacking_defends_total, crimes_total, crimes_version, items_used_energy, other_ranked_war_wins

**Estimated Time:**
- API calls: ~596,600 (190 users × 20 days × 157 stats)
- Time: ~2,983 minutes (49 hours) at 0.3s per call

## Safety Features

- ✅ Checks for existing snapshots before creating (no duplicates)
- ✅ Unique index on (user_id, date) prevents duplicates at DB level
- ✅ Stops processing user if API error occurs
- ✅ Handles rate limits gracefully
- ✅ Creates snapshots with proper historical dates
- ✅ Idempotent - safe to run multiple times

## Usage Example

```bash
# Step 1: Check what would be done (RECOMMENDED)
rails stats:backfill_2026_core_dry_run

# Step 2: Run the core backfill (if output looks good)
rails stats:backfill_2026_core

# Monitor progress - it will show each user as it processes
# Takes ~2 hours for 190 users × 20 days × 7 stats
```

## Notes

- The task uses OwnerCredentials.api_key for API access
- Snapshots are created with `created_at` set to noon of the historical date
- The `date` column ensures only one snapshot per user per day
- Progress is shown in real-time as users are processed
- The backfill is idempotent - you can stop and restart without issues

## Which Should I Use?

**Use Core Stats Backfill if:**
- ✅ You only need data for the faction page
- ✅ You want results quickly (2 hours)
- ✅ You don't need detailed attacking/trading/travel stats

**Use Full Stats Backfill if:**
- ✅ You plan to add more features using other stats
- ✅ You want comprehensive historical data
- ✅ You can let it run for 49 hours (or run it in batches)
