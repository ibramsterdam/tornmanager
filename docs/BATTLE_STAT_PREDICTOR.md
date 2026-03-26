# Battle Stat Predictor (BSP)

A system for estimating opponent battle stats using Fair Fight scores from attack logs, integrated into TornManager.

## Core Concept

When you attack someone in Torn, the API returns a **Fair Fight (FF) multiplier** (1x-3x). Since this multiplier is a function of the attacker's and defender's battle stat scores, we can reverse-engineer the defender's approximate stats if we know our own.

## The Math

### Battle Stat Score (BSS)

Each player has a Battle Stat Score derived from their four battle stats:

```
BSS = sqrt(strength) + sqrt(speed) + sqrt(defense) + sqrt(dexterity)
```

### Fair Fight Formula

```
FF = 1 + (8/3) * (Defender_BSS / Attacker_BSS)
```

- **FF = 3.0** means the defender has ~75% of your BSS (ideal target)
- **FF = 1.0** means the defender has ~0% of your BSS (very weak)
- **FF capped at 3.0** -- anyone at or above 75% BSS reads as 3.0
- Players hitting anyone above the **top 1000 HoF** battle stats always get FF 3.0

### Reverse Calculation (Estimating Defender BSS)

```
Defender_BSS = (FF - 1) * (3/8) * Attacker_BSS
```

### Limitations

- FF is capped at 3.0, so we can only establish a **minimum** BSS for targets that cap out
- A single BSS number can't tell you the stat *distribution* (e.g. STR-heavy vs balanced)
- Stealthed attacks don't reveal the defender
- Estimates should be treated as ~10% lower bound -- worst case (single-stat training) means the real total could be up to 4x higher than assumed from BSS alone

---

## Architecture Plan

### Phase 1: Data Collection

**Goal**: Collect FF scores from faction members' attack logs and store private/public BSS estimates.

#### New Torn API Endpoints Needed

| Selection | Purpose |
|-----------|---------|
| `user/battlestats` | Get attacker's own STR/SPD/DEF/DEX to calculate their private BSS |
| `user/attacks` | Get attack log with FF scores and defender IDs |
| `user/hof` | Identify top-1000 HoF players (excluded from FF estimation) |
| `user/personalstats` | Additional signals for ML model training (future) |

#### New Database Tables

```ruby
# battle_stat_estimates -- public BSS estimates for any player
create_table :battle_stat_estimates do |t|
  t.integer :player_id, null: false        # Torn player ID being estimated
  t.float :bss_public                      # Estimated public BSS
  t.datetime :bss_public_updated_at        # When this estimate was last refreshed
  t.integer :estimate_count, default: 0    # Number of independent estimates contributing
  t.float :bss_confidence                  # Confidence score (0-1) based on estimate count & agreement
  t.timestamps
end
add_index :battle_stat_estimates, :player_id, unique: true
add_index :battle_stat_estimates, :bss_public

# battle_stat_observations -- individual FF observations (raw data)
create_table :battle_stat_observations do |t|
  t.integer :attacker_id, null: false      # Torn player ID of attacker (our faction member)
  t.integer :defender_id, null: false       # Torn player ID of defender
  t.float :fair_fight, null: false          # FF score from the attack
  t.float :attacker_bss, null: false        # Attacker's BSS at time of attack
  t.float :estimated_defender_bss           # Calculated defender BSS
  t.datetime :attacked_at, null: false      # When the attack happened
  t.boolean :stealthed, default: false      # Whether the attack was stealthed
  t.timestamps
end
add_index :battle_stat_observations, :defender_id
add_index :battle_stat_observations, [:attacker_id, :defender_id]
add_index :battle_stat_observations, :attacked_at
```

#### New Jobs

- **`FetchAttackLogJob`** -- Per-user job (faction queue). Pulls recent attacks, calculates defender BSS from FF, stores observations.
- **`UpdateBattleStatEstimatesJob`** -- Aggregates observations into public estimates. Weighted by recency and attacker confidence.
- **`FetchBattleStatsJob`** -- Per-user job. Fetches the user's own battle stats to compute their private BSS. Raw stats are NOT stored -- only the BSS.

#### New Models

- `BattleStatEstimate` -- Public BSS for any player
- `BattleStatObservation` -- Individual FF-derived observations
- `TornApi::User::BattleStats` -- API wrapper for battlestats endpoint
- `TornApi::User::Attacks` -- API wrapper for attacks endpoint

### Phase 2: Estimation Engine

**Goal**: Turn raw observations into useful, accurate BSS estimates.

#### Aggregation Strategy

1. Collect all observations for a defender, sorted by recency
2. Weight recent observations higher (stats grow over time)
3. If multiple attackers estimate the same defender, cross-reference for accuracy
4. Handle FF = 3.0 cap: store as **minimum BSS** (defender is *at least* this strong)
5. Compute confidence score based on:
   - Number of independent observations
   - Agreement between different attackers' estimates
   - Recency of observations
   - Whether any observations hit the FF cap

#### Edge Cases

- **FF = 3.0 (capped)**: Defender BSS >= 75% of attacker BSS. Only gives a lower bound.
- **Top 1000 HoF**: Always returns FF 3.0 regardless. Must be flagged and excluded from normal estimation. Use HoF endpoint to identify these players.
- **Stealthed attacks**: No defender ID available -- skip.
- **Stat growth**: Players train daily. Old estimates decay in relevance. Apply time-based decay weighting.
- **Single-stat builds**: BSS assumes balanced stats. A player with all STR will have a BSS of `sqrt(total)` vs `4 * sqrt(total/4)` for balanced. The balanced player has 2x the BSS for the same total. Account for this uncertainty in confidence scoring.

### Phase 3: Public Prediction API

**Goal**: Expose a public API endpoint that returns a stat prediction for any player ID. This is the core deliverable -- any client (userscript, Discord bot, other tools) can consume it.

#### API Endpoint

```
GET /api/bsp/predict/:player_id
Authorization: Bearer <user_api_token>

Response:
{
  "player_id": 123,
  "predicted_total_stats": 11000000000,
  "display": "11b",
  "source": "spy",              // "spy" | "ff" | "ml"
  "confidence": 0.95,           // 0.0 - 1.0
  "updated_at": "2026-03-26T12:00:00Z"
}
```

#### Bulk Endpoint (for batch lookups)

```
GET /api/bsp/predict?player_ids=123,456,789
Authorization: Bearer <user_api_token>

Response:
{
  "predictions": {
    "123": { "predicted_total_stats": 11000000000, "display": "11b", "source": "spy", "confidence": 0.95, "updated_at": "..." },
    "456": { "predicted_total_stats": 6200000000, "display": "6.2b", "source": "ff", "confidence": 0.7, "updated_at": "..." },
    "789": { "predicted_total_stats": 4800000000, "display": "4.8b", "source": "ml", "confidence": 0.5, "updated_at": "..." }
  }
}
```

#### Source Priority

When multiple prediction sources exist for a player, return the best one:

1. **`spy`** -- exact stats from spy report (highest trust)
2. **`ff`** -- derived from fair fight observations (good trust)
3. **`ml`** -- model prediction from profile features (approximate)

#### Stat Formatting Helper

```ruby
def format_stats(total)
  if total >= 1_000_000_000
    "#{(total / 1_000_000_000.0).round(1)}b"
  elsif total >= 1_000_000
    "#{(total / 1_000_000.0).round(0)}m"
  elsif total >= 1_000
    "#{(total / 1_000.0).round(0)}k"
  else
    total.to_s
  end
end
```

#### Rate Limiting & Auth

- Authenticated via user API token (existing auth system)
- Rate limited per user to prevent abuse
- Bulk endpoint capped at ~50 player IDs per request

### Phase 4: ML Stat Predictor

**Goal**: Predict battle stats for players we've never attacked or spied, using profile features.

#### The Three-Layer Prediction Model

```
Layer 1: FF Reversal (math-only)
  - Input: FF score + attacker BSS
  - Output: defender BSS estimate
  - Coverage: anyone a faction member has attacked
  - Accuracy: good for BSS total, blind to stat distribution

Layer 2: Spy-Calibrated Ground Truth
  - Input: spy reports (from TornStats API or manual import)
  - Output: exact stats (STR, SPD, DEF, DEX) = labeled training data
  - Coverage: limited to spied targets (expensive/rare)
  - Accuracy: perfect (ground truth)

Layer 3: Profile-Based ML Prediction
  - Input: player profile features (see below)
  - Output: predicted total stats + estimated distribution
  - Coverage: anyone with visible personalstats (nearly everyone)
  - Accuracy: depends on training data volume and feature quality
```

#### Training Data Pipeline

When a spy report is logged for a target:

1. **Label**: Store the target's known stats (STR, SPD, DEF, DEX, total) from the spy report
2. **Features**: Fetch the target's `personalstats` and `profile` from Torn API
3. **Validate**: Cross-reference with any FF observations we have for this target
4. **Store**: Save as a training pair in `ml_training_samples`

Over time, this builds a labeled dataset: "for players with these profile characteristics, their actual stats were X."

#### Feature Candidates (ML inputs)

| Feature | Source | Why it's predictive |
|---------|--------|-------------------|
| Account age (days) | `profile` | Longer play = more training time |
| Level | `profile` | Rough proxy for overall progression |
| Xanax taken | `personalstats` | Direct stat training fuel (energy refills) |
| Cans used | `personalstats` | Energy drink usage for training |
| Energy refills | `personalstats` | More refills = more gym trains |
| Stat enhancers used | `personalstats` | Multiplies training gains |
| Faction ID / faction age | `profile` | Strong factions tend to have stronger members |
| Awards count | `profile` | General activity indicator |
| Networth | `personalstats` | Wealth correlates with progression |
| Times hospitalized | `personalstats` | Combat activity indicator |
| Attacks won/lost | `personalstats` | Fighting experience |
| SE sessions (>200) | existing HoF data | Heavy SE users have dramatically higher stats |
| Boosters used | `personalstats` | Temporary stat modifiers indicate active training |

#### New Database Table

```ruby
# ml_training_samples -- labeled data for model training
create_table :ml_training_samples do |t|
  t.integer :player_id, null: false

  # Labels (from spy reports)
  t.bigint :strength
  t.bigint :speed
  t.bigint :defense
  t.bigint :dexterity
  t.bigint :total_stats
  t.float :bss                           # Calculated BSS from known stats

  # Features (from personalstats + profile at time of spy)
  t.integer :account_age_days
  t.integer :level
  t.integer :xanax_taken
  t.integer :cans_used
  t.integer :energy_refills
  t.integer :stat_enhancers_used
  t.integer :attacks_won
  t.integer :attacks_lost
  t.bigint :networth
  t.integer :awards
  t.integer :times_hospitalized
  t.integer :boosters_used

  # Metadata
  t.datetime :spied_at                    # When the spy report was from
  t.datetime :features_fetched_at         # When personalstats were fetched
  t.string :spy_source                    # "tornstats" or "manual"

  t.timestamps
end
add_index :ml_training_samples, :player_id
add_index :ml_training_samples, :spied_at
```

#### Model Approach

Start simple, get more sophisticated as training data grows:

1. **Phase 4a -- Linear regression**: Total stats ~ f(age, xanax, cans, level, SE). Fast to train, easy to debug, works with small datasets (~100+ samples). Can run in pure Ruby with no ML dependencies.
2. **Phase 4b -- Random forest / gradient boosting**: Better for non-linear relationships (e.g. SE usage has diminishing returns). Consider Python microservice or use `rumale` gem for in-Ruby ML.
3. **Phase 4c -- Separate models per stat**: Predict STR/SPD/DEF/DEX independently for stat distribution estimation. Needs more training data.

#### Feedback Loop

```
Spy report comes in for Player X
        |
        v
Fetch Player X's personalstats + profile --> store as training sample
        |
        v
Check: do we have FF observations for Player X from our faction members?
        |
        v
Yes --> validate: does FF-derived BSS match spy-derived BSS?
        |         (if not, flag for investigation)
        v
Retrain model periodically with new labeled data
        |
        v
Model predicts stats for Player Y (never spied, never attacked)
        using only their public personalstats
```

### Phase 5: Advanced Features

**Goal**: Leverage the prediction system for tactical advantage.

- **Growth Rate Tracking**: Track BSS/stat changes over time to predict where a player will be in N days
- **Chain Target Optimization**: Find targets that maximize respect gain (FF close to 3.0) for chain building
- **War Scouting Reports**: Auto-generate pre-war intelligence reports combining BSS, ML predictions, activity patterns, and travel data
- **Confidence Tiers**: Show prediction source -- "spied" (exact), "FF-estimated" (good), "ML-predicted" (approximate) -- so users know how much to trust each estimate
- **Anomaly Detection**: Flag players whose ML-predicted stats diverge significantly from FF-observed BSS (possible single-stat builds, stat resets, or other edge cases)

---

## Data Flow

```
                    LAYER 1: FF REVERSAL
                    ====================
Faction Member registers API key
        |
        v
FetchBattleStatsJob --> calculates member's private BSS (raw stats discarded)
        |
        v
FetchAttackLogJob --> pulls attacks, pairs FF scores with private BSS
        |
        v
BattleStatObservation created for each non-stealthed attack
        |
        v
UpdateBattleStatEstimatesJob --> aggregates observations per defender
        |
        v
BattleStatEstimate updated (public BSS, confidence, timestamp)


                    LAYER 2: SPY CALIBRATION
                    ========================
Spy report imported (TornStats API or manual)
        |
        v
Known stats stored --> calculate true BSS
        |
        v
Cross-reference with FF observations --> validate accuracy
        |
        v
Fetch target's personalstats + profile
        |
        v
Store as ML training sample (labels + features)


                    LAYER 3: ML PREDICTION
                    ======================
New unknown player encountered
        |
        v
Fetch their personalstats + profile (public data)
        |
        v
Run through trained model
        |
        v
Predicted total stats + confidence interval
        |
        v
UI surfaces all three layers with confidence tiers:
  [Spied: exact] > [FF-estimated: good] > [ML-predicted: approximate]
```

## Privacy & Security Considerations

- **Never store raw battle stats of faction members** -- only the derived BSS score (same approach as FFScouter)
- **Never store attack logs** -- process and discard immediately
- **Never expose who contributed an estimate** -- only the aggregate result is public
- **Private BSS is per-user** -- never shown to other faction members
- **ML training samples store target stats** -- these are enemy/external players, not faction members. Spy data is already stored in spy_reports table.
- **Rate limiting** -- respect Torn API limits, use existing faction queue infrastructure

## API Key Requirements

BSP needs these Torn API v2 selections from faction member keys:

| Selection | Required | Purpose |
|-----------|----------|---------|
| `basic` | Yes | Player ID attribution |
| `battlestats` | Yes | Calculate private BSS |
| `attacks` | Yes | FF scores for estimation |
| `hof` | Yes | Exclude top-1000 from FF estimation |
| `personalstats` | Yes | ML training features (for targets) |
| `profile` | Yes | Age, level, faction context |

## External API Dependencies

| Service | Purpose |
|---------|---------|
| TornStats API | Import spy reports (existing integration) |
| Torn API v2 | All player data, attack logs, personalstats |

## Implementation Priority

1. **Database migrations + models** -- Foundation (estimates, observations, training samples)
2. **API wrappers** (battlestats, attacks, personalstats for targets) -- Data source
3. **FetchAttackLogJob + BSS calculation** -- Core FF reversal pipeline
4. **Aggregation engine** -- Turn observations into estimates
5. **Spy report -> training sample pipeline** -- Label collection
6. **Basic UI** (target finder table with confidence tiers) -- First usable feature
7. **War dashboard integration** -- High-value integration
8. **Linear regression model** -- First ML predictions
9. **Model iteration** (random forest, per-stat models) -- Accuracy improvement
10. **Advanced features** (growth tracking, chain optimization, scouting reports)

## Open Questions

- [ ] Should BSP be opt-in per faction member, or automatic for anyone with a registered API key?
- [ ] How often should we poll attack logs? Every hour? On-demand? After each chain?
- [ ] Should we expose a public API for BSS lookups (like FFScouter does)?
- [ ] What's the minimum number of observations before showing an estimate?
- [ ] How aggressively should old estimates decay? (Players can gain ~1-5% BSS/week from training)
- [ ] Should we integrate with FFScouter's API instead of/in addition to building our own?
- [ ] ML runtime: pure Ruby (rumale gem) vs Python microservice vs external ML API?
- [ ] How many training samples do we need before the ML model is useful? (~100 for linear, ~500+ for tree-based)
- [ ] Should we auto-fetch personalstats for every spied target, or batch it?
- [ ] How to handle stale training data? (spy from 6 months ago + current personalstats = mismatch)
