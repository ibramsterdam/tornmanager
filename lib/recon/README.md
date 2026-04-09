# Recon: Battle Stat Predictor

Predicts a Torn player's total battle stats (STR + DEF + SPD + DEX) from publicly available personalstats and profile data.

## Architecture

Training happens in Python (scikit-learn), inference in Ruby (ONNX Runtime).

```
lib/recon/train_model.py    # Python: trains Random Forest, exports ONNX
lib/recon/model.onnx         # Trained model artifact (gitignored)
lib/recon/.venv/             # Python venv (gitignored)
lib/recon/requirements.txt   # Python deps: scikit-learn, onnx, skl2onnx
lib/tasks/recon.rake         # rake recon:train

app/models/recon/predictor.rb     # Ruby: loads ONNX, runs inference
app/models/recon/feature_set.rb   # Ruby: builds feature vector from API data
app/models/recon/training_sample.rb  # ActiveRecord model for training data
```

## How to train

```bash
rake recon:train
# or directly:
lib/recon/.venv/bin/python3 lib/recon/train_model.py storage/development.sqlite3 lib/recon/model.onnx
```

Training takes ~5 seconds on 11k samples (vs 5+ minutes with the old pure-Ruby Rumale approach).

## How prediction works

1. Fetch player's personalstats + profile via Torn API (admin key)
2. `Recon::FeatureSet.build` creates a feature hash (22 DB columns + 8 engineered features)
3. `Recon::Predictor` applies log transforms, runs ONNX inference, inverts with `expm1`

The UI is at `/admin/recon` — enter a Torn ID, get a prediction via Turbo Stream.

## Model details

- **Algorithm**: Random Forest Regressor (200 trees, max_depth=10, min_samples_leaf=10)
- **Target**: `log1p(total_stats)` — log-space regression, inverted at prediction time
- **Cross-val R²**: 0.957 (log-space)
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

`total_energy` dominates because it directly measures lifetime training energy (xan, refills, energy drinks each give fixed energy amounts).

### Log transforms

Applied to heavy-tailed features before training: xantaken, energydrinkused, statenhancersused, boostersused, lsdtaken, revives, exttaken, victaken, rehabs, attackswon, networth, hospital, total_energy. Both Python and Ruby must apply the same transforms.

### Data cleaning (removes ~3.6% of samples)

1. **Zero-stat samples** (79): spy records where actual stats weren't captured — high-level players with 0 total stats
2. **Unbalanced builds** (106): one stat >95% of total — likely data errors
3. **Outliers**: top/bottom 1% by log(total_stats)

## Known issues and limitations

### Temporal gap (biggest source of error)
Training data pairs spy-time stats with spy-time personalstats. Live predictions use *current* personalstats, which are always higher than at spy time. This causes systematic overestimation, typically 5-20% depending on how much the player has grown since their features last matched the training distribution.

### Stat enhancer users distort predictions
Players with SE >= 3 have ~7x the stats of SE=0 players at the same energy level. The model blends them, pulling predictions up for non-SE players. A `has_se` binary feature (SE >= 3, to exclude merit-only users) was added but `total_energy` dominates so heavily (86%) that the tree splits on energy first and the SE signal gets lost. The SE=1-2 group (merit hunters) also has 2x stats vs SE=0.

### Sparse data ranges
The training data is heavily concentrated in the 1B-10B stat range (54% of samples). Sparse areas:

| Stat Range | Count | Status |
|---|---|---|
| 50M - 100M | 193 | SPARSE |
| 25B - 50B | 123 | SPARSE |
| 50B+ | 147 | SPARSE |
| 10M - 50M | 469 | Thin |
| 100M - 250M | 379 | Thin |
| 250M - 500M | 449 | Thin |

More spy data in the 10M-500M and 25B+ ranges would improve predictions significantly.

### Real-world comparison (2026-04-08)

Tested against real spies, BSP (userscript), and FFScouter estimates:

| Player | Real Spy | BSP | FFScouter | Ours | Our Error |
|---|---|---|---|---|---|
| 2684760 | 5.49B | 5.3B (3.5% under) | 5.61B (2.1% over) | 5.66B | 3.0% over |
| 2445730 | 5.62B | 5.8B (3.2% over) | 5.81B (3.4% over) | 6.01B | 6.9% over |

Model is competitive in the 1B-10B range (bulk of training data). Weaker in sparse ranges.

### Min-maxers
Players who optimize stat growth efficiency have unusual energy-to-stats ratios. The model predicts the average relationship, which can be 20%+ off for these players.

## Next steps to explore

These were discussed but not yet implemented:

1. **FFScouter API validation** — FFScouter (ffscouter.com) is an external service that also estimates battle stats. Their API (`GET /api/v1/get-stats?key=...&targets=...`) returns `bs_estimate` for players. Could be used to:
   - **Validate**: compare both models' accuracy against known spy data
   - **Feature**: use their estimate as an input feature (adds dependency)
   - **Ensemble**: average predictions at inference time
   - Do NOT use as training data (would learn their model's biases, not ground truth)
   - Rate limit: 20 req/min, up to 205 targets per request
   - Requires API key registration

2. **Tier segmentation** — train separate models for different stat brackets (e.g., sub-1B, 1B-10B, 10B+). Each model would learn tighter relationships within its range.

3. **More feature engineering** — ratios like `attackswon / level`, `networth / level`. Drop-one analysis showed most current features add negligible value; only daysbeendonator, total_energy, attackswon, and awards meaningfully contribute.

4. **Feature selection** — the "Top 10" feature set (total_energy, awards, daysbeendonator, jobpointsused, xantaken, refills, attackswon, networth, highestbeaten, xan_per_day) achieves R²=0.9556 — nearly identical to all 30 features. Fewer features = less noise.

5. **Alternative models** — GradientBoosting was tested but performed worse for edge cases (R²=0.78, worse calibration for specific players). Random Forest was better overall.

## Contract between Python and Ruby

The feature list and transforms must stay in sync across three files:

- `lib/recon/train_model.py` — `ALL_FEATURES`, `LOG_FEATURES`, `add_engineered_features()`
- `app/models/recon/predictor.rb` — `FEATURE_ORDER`, `LOG_FEATURES`
- `app/models/recon/feature_set.rb` — `add_engineered_features()`

If you add/remove/reorder features in Python, you must update both Ruby files and retrain.
