# Recon -- Battle Stat Predictor

Predict any Torn player's total battle stats using ML trained on spy reports + public personalstats. Exposed as a public API endpoint.

All Recon code lives under the `Recon::` namespace, fully separated from the rest of TornManager.

---

## Namespace: `Recon::`

```
app/
  models/
    recon/
      training_sample.rb        # Recon::TrainingSample
      model.rb                  # Recon::Model
      prediction.rb             # Recon::Prediction (cached predictions)
      predictor.rb              # Recon::Predictor (prediction service)
      trainer.rb                # Recon::Trainer (model training logic)
      feature_extractor.rb      # Recon::FeatureExtractor (API -> features hash)
      outlier_detector.rb       # Recon::OutlierDetector
      spy_report.rb             # Recon::SpyReport (Recon's own spy data, separate from faction spy_reports)
    recon/
      torn_api/
        personal_stats.rb       # Recon::TornApi::PersonalStats (cat=popular or stat+timestamp)
        profile.rb              # Recon::TornApi::Profile (age, level, property, last_action)
      torn_stats_api/
        spy_report.rb           # Recon::TornStatsApi::SpyReport (import into recon_spy_reports)
  jobs/
    recon/
      collect_training_sample_job.rb
      backfill_training_samples_job.rb
      train_model_job.rb
      validate_from_attacks_job.rb
  controllers/
    api/
      recon_controller.rb
```

Database tables are prefixed with `recon_`.

---

## Core Concept

1. **Spy reports** give us exact stats (labels) -- used for training only, never exposed
2. **Public personalstats + profile** give us player activity data (features)
3. Train a random forest on (features -> total stats), then predict for anyone
4. **FF observations** from faction attacks act as a floor and validation layer

---

## Features (ML Inputs)

Based on TDup's confirmed BSP feature list and our own analysis. TDup uses 12 features -- we start with a similar lean set and let feature importance guide expansion.

### Core Features (proven by BSP)

These are TDup's confirmed working features, adapted to our API field names:

| Feature | API field | Notes |
|---------|-----------|-------|
| Xanax taken | `xantaken` | #1 predictor. Each xanax = 250E for gym. |
| Energy drinks used | `energydrinkused` | Each can = 5-30E. |
| Energy refills | `refills` | Each refill = full energy bar. |
| Stat enhancers used | `statenhancersused` | +1% to a single stat per use. Scales with base stats. |
| Boosters used | `boostersused` | FHC = 100-150E on 6h cooldown. Key endgame energy source. |
| LSD taken | `lsdtaken` | Each LSD = 50E. Minor energy source but TDup includes it. |
| Revives | `revives` | Active player signal. TDup confirmed useful. |
| Attacks won | `attackswon` | Combat activity. |
| Awards | `awards` | General progression. |
| Donator days | `daysbeendonator` | 150E/5h vs 100E/5h natural regen. |
| Activity time | `useractivity` | Raw seconds of playtime. |
| Real age | derived | `age - days_since_last_action`. Inactive accounts treated as younger. (TDup: "AgeNonInactive") |

### Additional Features (our additions, validate via feature importance)

| Feature | API field | Why |
|---------|-----------|-----|
| Level | `level` (profile) | General progression. |
| Property happy cap | `property` (profile) | PI = 4,225 happy vs Castle ~2,700. Impacts gym gains. |
| Networth | `networth` | Wealth enables xanax/SE purchasing. |
| Ecstasy taken | `exttaken` | Doubles happiness for happy jumps. |
| Vicodin taken | `victaken` | Happy jump strategy signal. |
| Rehabs | `rehabs` | Restores happiness for training. |
| Highest beaten | `highestbeaten` | Direct combat capability signal. |
| Times hospitalized | `hospital` | Combat exposure. |
| Job points used | `jobpointsused` | Company job points convert to energy. |
| Trains received | `trainsreceived` | Direct stat trains from company. |

After the first training cycle, prune any feature with importance < 0.01.

### Features We Skip

| Field | Why skip |
|-------|----------|
| Mails, personals, classified ads | No stat relevance |
| Travel destinations | No stat correlation |
| Crime skills | Crime progression != stat progression |
| Bazaar/trading stats | Economic activity, not stat-related |
| Bounty stats | No stat relevance |
| Weapon hit types | Fighting style, not stat level |

---

## Outlier Detection & Flagging

### The Problem

Real data shows extreme stat distributions:
- **Trole**: 18.6b total, but only 297m DEX (1.6% of total)
- **Wasbeer**: 2.5b total, but only 1,124 DEX (0.00004%)
- **CockyNudist** (TDup's example): Takes xanax but never trains. BSP predicts 3b, actual is 40 TBS.

Two categories of outliers:
1. **Unbalanced builds** -- high total but lopsided distribution. ML predicts total correctly, but BSS will be lower than expected.
2. **Non-trainers** -- high activity stats (xanax, etc.) but spend energy on attacks/crimes, not gym. ML overpredicts. These are rare edge cases.

### `Recon::OutlierDetector`

Uses FF observations as validation:

```ruby
class Recon::OutlierDetector
  def detect(player_id)
    prediction = Recon::Prediction.find_by(player_id:)
    ff_bss = latest_ff_derived_bss(player_id)

    return :unknown unless prediction && ff_bss

    expected_bss = 2 * Math.sqrt(prediction.predicted_total)
    ratio = ff_bss / expected_bss

    if ratio < 0.7
      :unbalanced
    else
      :balanced
    end
  end
end
```

### API Response Flags

```json
{
  "player_id": 1485341,
  "predicted_total_stats": 18600000000,
  "display": "18.6b",
  "confidence": 0.7,
  "flags": ["unbalanced_build"],
  "updated_at": "2026-03-27T12:00:00Z"
}
```

Possible flags:
- `"unbalanced_build"` -- FF-derived BSS much lower than expected for predicted total
- `"low_confidence"` -- model confidence below threshold
- `"ff_floor_applied"` -- FF data proved player is stronger than ML predicted

---

## Architecture

### Phase 1: Training Data Collection

**Goal**: Build a labeled dataset pairing spy reports with public personalstats. Target: 1000+ samples/month.

#### Pipeline

```
Spy report imported (TornStats, manual, or faction member)
        |
        v
Recon::CollectTrainingSampleJob:
  1. Fetch player's personalstats (cat=popular) from Torn API
  2. Fetch player's profile from Torn API
  3. Extract features via Recon::FeatureExtractor
  4. Store (features, labels) pair in recon_training_samples
```

#### `Recon::FeatureExtractor`

```ruby
class Recon::FeatureExtractor
  PERSONALSTAT_KEYS = %w[
    xantaken energydrinkused refills statenhancersused boostersused
    lsdtaken revives attackswon awards daysbeendonator useractivity
    networth exttaken victaken rehabs highestbeaten hospital
    jobpointsused trainsreceived
  ].freeze

  PROPERTY_HAPPY = {
    "Private Island" => 4225, "Palace" => 3000, "Castle" => 2700,
    "Mansion" => 1500, "Villa" => 1000, "Penthouse" => 500
  }.freeze

  def extract(personalstats:, profile:)
    features = {}

    PERSONALSTAT_KEYS.each do |key|
      features[key] = personalstats[key] || 0
    end

    features["level"] = profile["level"] || 0
    features["property_happy"] = PROPERTY_HAPPY.find { |k, _| profile["property"]&.include?(k) }&.last || 200

    # Derived: real age = account age minus inactivity (hat tip: TDup/BSP "AgeNonInactive")
    age = profile["age"] || 0
    last_action_ts = profile.dig("last_action", "timestamp")
    days_inactive = last_action_ts ? ((Time.now.to_i - last_action_ts) / 86_400.0).round : 0
    features["real_age"] = [age - days_inactive, 0].max

    features
  end
end
```

#### Database Tables

Recon owns its own spy data -- completely separate from the faction `spy_reports` table. No `faction_id`, no trace of who contributed.

```ruby
# Recon's own spy data store -- voluntarily contributed, never auto-pulled from factions
create_table :recon_spy_reports do |t|
  t.integer :player_id, null: false
  t.bigint :strength, null: false
  t.bigint :defense, null: false
  t.bigint :speed, null: false
  t.bigint :dexterity, null: false
  t.bigint :total_stats, null: false
  t.datetime :spied_at, null: false
  t.timestamps
end
add_index :recon_spy_reports, :player_id
add_index :recon_spy_reports, :spied_at

# Training samples = recon_spy_reports + fetched personalstats features
create_table :recon_training_samples do |t|
  t.integer :player_id, null: false
  t.bigint :total_stats, null: false
  t.json :features, null: false
  t.datetime :spied_at, null: false
  t.timestamps
end
add_index :recon_training_samples, :player_id
add_index :recon_training_samples, :spied_at
```

#### Data Flow

```
recon_spy_reports (voluntarily contributed spy data)
        |
        v
Recon::CollectTrainingSampleJob:
  - Fetch personalstats + profile for the player
  - Store (features, total_stats) in recon_training_samples
```

#### How Spy Data Gets Into Recon

For now: manually import from your own faction's spy data or directly from TornStats.

Future: factions can opt-in to sync their `spy_reports` → `recon_spy_reports`. This is a one-way copy -- deleting faction data doesn't affect Recon's training data.

#### Trigger Points

1. **Direct import** -- admin action to bulk import spy data into `recon_spy_reports`
2. **Future: faction opt-in sync** -- opted-in factions auto-copy new spy reports to Recon
3. **On new recon_spy_report** -- enqueue `Recon::CollectTrainingSampleJob` to fetch features

#### Historical Backfill

The Torn API supports fetching personalstats at any point in time via the `timestamp` parameter. This means we can pair **old spy reports** with historical personalstats to create valid training samples immediately.

```
For each historical spy report (spied_at = e.g. 3 months ago):
  1. Fetch personalstats at spied_at timestamp (2 API calls, 10 stats each)
  2. Fetch profile (age/level are less time-sensitive, current values are acceptable)
  3. Store as training sample
```

**Constraints:**
- `timestamp` only works with the `stat` parameter (not `cat=popular`), max 10 stats per request
- So 2 API calls per player: batch 1 (10 stats) + batch 2 (remaining stats)
- Rate limited: ~25 players/min = ~1500 players/hour
- 3,000 old spies ≈ 2 hours of backfill

**New job:** `Recon::BackfillTrainingSamplesJob` -- iterates over `recon_spy_reports` that don't have a corresponding `recon_training_samples` entry, fetches historical personalstats, creates samples.

**Worst case:** If historical data turns out to be noisy or inaccurate, truncate `recon_training_samples`, re-import with fresh spies only, retrain. The infrastructure stays the same.

### Phase 2: ML Model

**Goal**: Train a random forest that predicts total stats from personalstats features.

#### Why Random Forest

Gym training in Torn is deeply non-linear:
- Gains formula: `gain ∝ ln(happy) * current_stat_total`
- Growth decays: 212%/month at 50m → 3.4%/month at 10b → 2.2%/month at 100b
- SE gives +1% per use to a single stat -- value scales with base stats
- Specialist gyms (8.0 multiplier) require stat ratios, creating single-stat builds
- Below ~400k stats: happiness > energy. Above: energy > happiness
- Modifiers stack multiplicatively (faction, education, company, books, property)

Random forest discovers these thresholds and interactions automatically. Confirmed as the winning model type by TDup/BSP via AutoML (ML.NET tried many models, random forest won).

```ruby
require "rumale"

model = Rumale::Ensemble::RandomForestRegressor.new(
  n_estimators: 200,
  max_depth: 15,
  min_samples_leaf: 5,
  random_seed: 42
)
model.fit(x_train, y_train)  # raw feature values, raw total_stats
```

#### SE Shortcut

BSP uses a shortcut: if `statenhancersused > 250`, skip ML and calculate from SE alone. At high SE counts, SE dominates all other stat sources. Consider implementing:

```ruby
# If SE > 250, rough estimate: each SE ≈ 1% of total, so total ≈ SE * avg_stat_at_time_of_use
# This is a fallback heuristic, not a primary prediction method
```

Evaluate whether our random forest handles high-SE players well enough to skip this.

#### Feature Importance

After training, extract importance to guide feature selection:

```ruby
importance = model.feature_importances
# Prune features with importance < 0.01 in next training cycle
```

#### Model Storage

```ruby
create_table :recon_models do |t|
  t.binary :serialized_model, null: false  # Marshal.dump of Rumale model
  t.json :feature_names, null: false       # Ordered list of feature names
  t.json :feature_importances              # { "xantaken": 0.28, ... }
  t.integer :sample_count, null: false
  t.float :r_squared
  t.float :mean_absolute_error
  t.float :median_absolute_percentage_error
  t.boolean :active, default: false
  t.timestamps
end
```

#### Training: `Recon::Trainer`

```ruby
class Recon::Trainer
  def train!
    samples = Recon::TrainingSample.all.to_a.shuffle(random: Random.new(42))
    return if samples.size < 100

    feature_names = Recon::FeatureExtractor::PERSONALSTAT_KEYS + %w[level property_happy real_age]
    x = Numo::DFloat.cast(samples.map { |s| feature_names.map { |f| s.features[f] || 0 } })
    y = Numo::DFloat.cast(samples.map(&:total_stats))

    split = (samples.size * 0.8).to_i
    x_train, x_test = x[0...split, true], x[split.., true]
    y_train, y_test = y[0...split], y[split..]

    model = Rumale::Ensemble::RandomForestRegressor.new(
      n_estimators: 200, max_depth: 15, min_samples_leaf: 5, random_seed: 42
    )
    model.fit(x_train, y_train)

    predictions = model.predict(x_test)
    r_squared = calculate_r_squared(y_test, predictions)
    mae = (y_test - predictions).abs.mean
    mape = ((y_test - predictions).abs / y_test * 100).median

    Recon::Model.create!(
      serialized_model: Marshal.dump(model),
      feature_names:,
      feature_importances: feature_names.zip(model.feature_importances).to_h,
      sample_count: samples.size,
      r_squared:,
      mean_absolute_error: mae,
      median_absolute_percentage_error: mape,
      active: r_squared > 0.6
    )
  end
end
```

#### Cached Predictions

```ruby
create_table :recon_predictions do |t|
  t.integer :player_id, null: false
  t.bigint :predicted_total, null: false
  t.float :confidence
  t.json :flags, default: []
  t.json :features                       # For debugging
  t.integer :recon_model_id
  t.timestamps
end
add_index :recon_predictions, :player_id, unique: true
```

#### Retraining

- Weekly scheduled job (adding ~250 samples/week)
- Manual trigger via admin
- Trains on ALL samples from scratch (random forest doesn't do incremental learning)
- New model activated only if metrics >= current active model
- Old models kept for comparison

### Phase 3: Public Prediction API

**Goal**: `GET /api/recon/:player_id` returns a stat prediction.

#### Single Lookup

```
GET /api/recon/:player_id

{
  "player_id": 249471,
  "predicted_total_stats": 14500000000,
  "display": "14.5b",
  "confidence": 0.72,
  "flags": [],
  "updated_at": "2026-03-27T12:00:00Z"
}
```

#### Bulk Lookup

```
GET /api/recon?player_ids=249471,1485341,3570129

{
  "predictions": {
    "249471":  { "predicted_total_stats": 14500000000, "display": "14.5b", "confidence": 0.72, "flags": [] },
    "1485341": { "predicted_total_stats": 18600000000, "display": "18.6b", "confidence": 0.68, "flags": ["unbalanced_build"] },
    "3570129": { "predicted_total_stats": 170390,      "display": "170k",  "confidence": 0.55, "flags": [] }
  }
}
```

#### Prediction Flow

```
GET /api/recon/:player_id
        |
        v
[1] Cached prediction < 5 days old? --> return it
        |
        no
        v
[2] Fetch personalstats (cat=popular) + profile (cached 24h per player)
        |
        v
[3] Recon::FeatureExtractor --> features hash
        |
        v
[4] Recon::Predictor: feed features into active random forest model
        |
        v
[5] FF floor check: is there an FF observation (< 15 days old)
    where FF-derived total > ML predicted total?
        |
    yes --> use FF-derived total instead, add flag "ff_floor_applied"
        |
        no
        v
[6] Recon::OutlierDetector: check for unbalanced build flag
        |
        v
[7] Cache in recon_predictions (5 day TTL), return response
```

**Key design decisions:**
- All predictions come from ML. Spy data is training-only, never exposed.
- FF acts as a **floor** -- if FF proves the player is stronger than ML thinks, use the higher value. (Learned from BSP architecture.)
- Predictions cached 5 days (matching BSP). Personalstats/profile cached 24h.
- 2 Torn API calls per uncached prediction (personalstats + profile).

#### Stat Formatting

```ruby
module Recon
  module StatsFormatter
    def self.format(total)
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
  end
end
```

#### Auth & Rate Limiting

- Authenticated via existing user session or API token
- Rate limited: 50 Torn API calls/min max (staying under Torn's 100/min hard limit)
- Bulk endpoint capped at 25 player IDs per request (each needs 2 API calls if uncached)

### Phase 4: FF Validation & Floor

**Goal**: Use faction attack data to validate predictions and act as a minimum bound.

#### Pipeline

```
Recon::ValidateFromAttacksJob (periodic)
        |
        v
Fetch /faction/attacks (outgoing, FF < 3.0 only)
        |
        v
For each attack where attacker stats are known (spy report):
  1. attacker_bss = sqrt(STR) + sqrt(SPD) + sqrt(DEF) + sqrt(DEX)
  2. defender_bss = (FF - 1) * (3/8) * attacker_bss
  3. Convert to estimated total: defender_total_estimate = (defender_bss / 2)^2
     (balanced assumption -- this is a minimum bound)
  4. Store in recon_ff_observations
  5. If estimate > existing ML prediction for this defender:
     update prediction with FF floor, add "ff_floor_applied" flag
```

**Why FF < 3.0 only**: At FF 3.0 the value is capped -- you only know "at least this strong." Below 3.0 gives exact BSS. (Confirmed by BSP: "Attacks received or given, that yielded less than 3 FF, will be used to compute your enemy bscore.")

#### Database Table

```ruby
create_table :recon_ff_observations do |t|
  t.integer :attacker_id, null: false
  t.integer :defender_id, null: false
  t.float :ff_score, null: false
  t.float :attacker_bss, null: false
  t.float :defender_bss, null: false
  t.bigint :estimated_total                # Balanced assumption minimum
  t.datetime :attacked_at, null: false
  t.timestamps
end
add_index :recon_ff_observations, :defender_id
add_index :recon_ff_observations, :attacked_at
```

### Phase 5: Advanced Features

- **Confidence intervals**: Return ranges ("8b-12b") instead of point estimates
- **Growth tracking**: Store prediction history per player, show trends
- **War scouting reports**: Auto-generate pre-war intel for enemy factions
- **Chain target finder**: Find players where predicted stats yield ~FF 3.0
- **Model explainability**: Show top contributing features per prediction
- **Per-stat models**: Predict STR/DEF/SPD/DEX individually (needs lots of data)

---

## Competitive Analysis: BSP (TDup) vs Recon

| Aspect | BSP (TDup) | Recon (ours) |
|--------|-----------|--------------|
| Model type | Random forest (via ML.NET AutoML) | Random forest (via Rumale, pure Ruby) |
| Training labels | FF-reversed BSS (57k) + spies | Spy reports only (1000+/month, exact total stats) |
| Predicts | BSS → then converts to total stats | Total stats directly (no conversion error) |
| Features | 12 (lean, proven) | 12 core + ~10 additional (validate via importance) |
| SE handling | >250 SE: skip ML, use math formula | Let RF handle it, evaluate if shortcut needed |
| Weak players | Separate "WeakModel" (<4k bscore) | Single model, RF handles range naturally |
| FF integration | FF > ML when FF is recent + higher | FF as floor only (same pattern) |
| Caching | 5 days ML, 15 days FF | 5 days predictions, 24h personalstats |
| HoF handling | Manual insert from public HoF thread | Not yet planned |
| Architecture | C#/.NET backend + userscript | Rails API endpoint, any client can consume |

**Our advantages:**
- Labels from spy reports (exact total stats) vs FF-derived BSS (estimated, conversion error)
- Predict total stats directly, no BSS→total conversion step
- Single model approach (simpler, RF handles range variation)

**Their advantages:**
- 57k training data points vs our ~1k/month starting
- Battle-tested over 2+ years
- Crowdsourced FF data from opted-in users

---

## API Calls Per Prediction

Two Torn API calls per player (both use a public key):

1. `GET /user/:id/personalstats?cat=popular` -- all 150+ stats
2. `GET /user/:id/profile` -- age, level, property, last_action

Use `cat=popular` (not `cat=all`) to reduce Torn server load. Both responses cached 24h.

### API Key Requirements

| Key | Endpoint | Purpose |
|-----|----------|---------|
| Public API key | `GET /user/:id/personalstats?cat=popular` | Fetch features |
| Public API key | `GET /user/:id/profile` | Fetch age, level, property |
| Faction API key | `GET /faction/attacks?filters=outgoing` | FF observations |

### Rate Limits

- Torn enforces 100 API calls/min per key
- We cap at 50 calls/min (same strategy as BSP) to leave headroom
- 2 calls per uncached prediction = max 25 new predictions/min
- Caching (5 day predictions, 24h personalstats) mitigates most repeated lookups

## External Dependencies

| Dependency | Purpose |
|------------|---------|
| `rumale` gem | Random forest implementation (pure Ruby) |
| `numo-narray` gem | Numeric arrays for rumale |
| TornStats API | Spy report imports (existing integration) |
| Torn API v2 | personalstats, profile, faction attacks |

## Implementation Priority

1. **Migrations**: `recon_spy_reports`, `recon_training_samples`, `recon_models`, `recon_predictions`, `recon_ff_observations`
2. **`Recon::FeatureExtractor`** + API wrapper for personalstats/profile (public key)
3. **`Recon::CollectTrainingSampleJob`** + **`Recon::BackfillTrainingSamplesJob`** -- start collecting new + backfill historical
4. **`Recon::Trainer`** -- random forest training with 80/20 evaluation
5. **`Recon::Predictor`** -- prediction service with caching + FF floor
6. **`Api::ReconController`** -- public API endpoint (`/api/recon/:player_id`)
7. **`Recon::ValidateFromAttacksJob`** -- FF observations + floor logic
8. **`Recon::OutlierDetector`** -- flag unbalanced builds
9. **Feature pruning** -- analyze importance, drop useless features, retrain

## Open Questions

- [ ] Minimum training samples before serving predictions? (100 seems safe for RF)
- [ ] Do we need the SE > 250 shortcut, or does RF handle it well enough?
- [ ] Should we add HoF data (manual or via API) for top players?
- [ ] How to handle old spy training data? (Player spied 6 months ago -- their personalstats also changed, so the pair is still valid as a historical data point)
- [ ] Rate limit on public API -- per user? per faction? global?
