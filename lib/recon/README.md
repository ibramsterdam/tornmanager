# Recon: Battle Stat Predictor

Predicts a Torn player's total battle stats (STR + DEF + SPD + DEX) from publicly available personalstats and profile data.

## Architecture

Training happens in Python (scikit-learn), inference in Ruby (ONNX Runtime).

```
lib/recon/train_model.py          # Python: trains models, exports ONNX
lib/recon/model_global.onnx       # Global model (gitignored)
lib/recon/model_low.onnx          # Tier: < 1B (gitignored)
lib/recon/model_mid.onnx          # Tier: 1B - 5B (gitignored)
lib/recon/model_high.onnx         # Tier: 5B+ (gitignored)
lib/recon/.venv/                   # Python venv (gitignored)
lib/recon/requirements.txt         # Python deps: scikit-learn, onnx, skl2onnx
lib/tasks/recon.rake               # rake recon:train

app/models/recon/predictor.rb      # Ruby: loads ONNX models, routes between tiers
app/models/recon/feature_set.rb    # Ruby: builds feature vector from API data
app/models/recon/training_sample.rb   # ActiveRecord model for training data
app/controllers/admin/recon_controller.rb  # Predict + Quick Add + Import
```

## How to train

```bash
rake recon:train
# or directly:
lib/recon/.venv/bin/python3 lib/recon/train_model.py storage/development.sqlite3 lib/recon
```

If the venv doesn't exist yet:
```bash
python3 -m venv lib/recon/.venv
lib/recon/.venv/bin/pip install -r lib/recon/requirements.txt
```

Training takes ~5 seconds on 11k samples.

## How prediction works

1. Fetch player's personalstats + profile via Torn API (admin key)
2. `Recon::FeatureSet.build` creates a feature hash (22 DB columns + 8 engineered)
3. `Recon::Predictor` runs the global model to get a rough estimate
4. The rough estimate picks a tier (< 1B, 1B-5B, 5B+)
5. The tier-specific model gives a refined prediction

The UI is at `/admin/recon` — enter a Torn ID to predict, or manually add training samples via Quick Add.

## Tiered model strategy

Instead of one model predicting across the entire stat range, there are three specialized models plus a global router:

- **Global** — trained on all data, used to pick the right tier
- **Low** (< 1B) — specialized for sub-1B players
- **Mid** (1B-5B) — specialized for the mid range
- **High** (5B+) — specialized for high-stat players

This improves accuracy because the relationship between features and stats differs across tiers. A player with 500M stats looks very different from one with 10B, even with similar features.

## Model details

- **Algorithm**: Random Forest Regressor (200 trees, max_depth=10, min_samples_leaf=10)
- **Target**: `log1p(total_stats)` — log-space regression, inverted at prediction time
- **Training samples**: ~11,100 (after cleaning)

### Features (30 total)

22 raw DB features from personalstats/profile + 8 engineered:

| Feature | Description | Importance |
|---|---|---|
| total_energy | xan*250 + refills*150 + edrink*100 | 86% |
| awards | Total awards earned | 7.3% |
| daysbeendonator | Donator days | 3.4% |
| jobpointsused | Job points used | 0.5% |
| xantaken | Xanax consumed | 0.4% |
| refills | Energy refills | 0.3% |
| ... | 24 others | <0.3% each |

`total_energy` dominates because it directly measures lifetime training energy.

### Log transforms

Applied to heavy-tailed features before training: xantaken, energydrinkused, statenhancersused, boostersused, lsdtaken, revives, exttaken, victaken, rehabs, attackswon, networth, hospital, total_energy.

### Data cleaning (removes ~3.6% of samples)

1. **Zero-stat samples**: spy records where actual stats weren't captured
2. **Unbalanced builds**: one stat >95% of total — likely data errors
3. **Outliers**: top/bottom 1% by log(total_stats)

## Validated accuracy (out-of-sample, 5-fold CV)

### Single model

| Tier | Samples | Median Error | Within ±10% | Within ±25% |
|---|---|---|---|---|
| < 100M | 2,082 | 50.5% | 11% | 27% |
| 100M - 500M | 803 | 48.2% | 13% | 29% |
| 500M - 1B | 733 | 28.1% | 19% | 45% |
| 1B - 5B | 4,076 | 12.8% | 40% | 76% |
| 5B - 10B | 2,151 | 9.2% | 54% | 88% |
| 10B+ | 1,296 | 10.5% | 48% | 84% |
| **ALL** | **11,141** | **16.0%** | **35%** | **64%** |

### Tiered model (current)

| Tier | Samples | Median Error | Within ±10% | Within ±25% |
|---|---|---|---|---|
| < 100M | 2,082 | 49.9% | 12% | 28% |
| 100M - 500M | 803 | 45.2% | 14% | 30% |
| 500M - 1B | 733 | 27.3% | 19% | 46% |
| 1B - 5B | 4,076 | 11.2% | 46% | 83% |
| 5B - 10B | 2,151 | 8.3% | 59% | 92% |
| 10B+ | 1,296 | 10.1% | 49% | 87% |
| **ALL** | **11,141** | **14.3%** | **38%** | **68%** |

### Real-world comparison (2026-04-08)

| Player | Real Spy | BSP | FFScouter | Ours | Our Error |
|---|---|---|---|---|---|
| 2684760 | 5.49B | 5.3B (3.5% under) | 5.61B (2.1% over) | 5.66B | 3.0% over |
| 2445730 | 5.62B | 5.8B (3.2% over) | 5.81B (3.4% over) | 6.01B | 6.9% over |

## Known issues and limitations

### Stat enhancer users distort predictions
Players with SE >= 3 have ~7x the stats of SE=0 players at the same energy level. The model blends them, pulling predictions up for non-SE players. SE=1-2 (merit hunters) have 2x stats vs SE=0.

### Sparse data ranges
Training data is heavily concentrated in 1B-10B (54%). The sub-500M range has high error purely from lack of training data. Target: 20k+ samples with better sub-500M coverage.

### Min-maxers
Players who optimize training efficiency unusually high or low break the "average" relationship. The model predicts the mean for a given feature profile.

### total_energy is a crude proxy
It ignores natural energy, gym unlocks, faction perks, happy jumps, and training efficiency. Two players with the same xan count can have very different actual energy spent training.

## Next steps

1. **More training data** — especially sub-500M. 20k+ samples recommended before revisiting model architecture.
2. **FFScouter API validation** — compare estimates systematically. API at `ffscouter.com/api/v1/get-stats`. Not yet integrated.
3. **Feature selection** — top 10 features get R²=0.9556 vs 0.9568 for all 30. Could simplify.

## Contract between Python and Ruby

The feature list and transforms must stay in sync across three files:

- `lib/recon/train_model.py` — `ALL_FEATURES`, `LOG_FEATURES`, `TIERS`, `add_engineered_features()`
- `app/models/recon/predictor.rb` — `FEATURE_ORDER`, `LOG_FEATURES`, `TIERS`
- `app/models/recon/feature_set.rb` — `add_engineered_features()`

If you add/remove/reorder features, update all three and retrain.
