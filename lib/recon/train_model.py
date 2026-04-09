#!/usr/bin/env python3
"""Train Random Forest models on recon training samples and export to ONNX.

Trains a global model (for routing) plus tier-specific models for refined predictions.
"""

import sqlite3
import sys
from pathlib import Path

import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import cross_val_score
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType

# Raw DB columns fetched from the database
DB_FEATURE_COLUMNS = [
    "xantaken", "energydrinkused", "refills", "daysbeendonator",
    "statenhancersused", "boostersused", "lsdtaken", "revives",
    "exttaken", "victaken", "rehabs", "highestbeaten", "hospital",
    "jobpointsused", "trainsreceived", "attackswon", "awards",
    "useractivity", "networth", "level", "property_happy", "real_age",
]

# Engineered features appended after DB columns
ENGINEERED_FEATURES = [
    "xan_per_day",           # xantaken / real_age — daily xan rate
    "refills_per_day",       # refills / real_age — daily refill rate
    "edrink_per_day",        # energydrinkused / real_age — daily energy drink rate
    "se_per_day",            # statenhancersused / real_age — daily SE rate
    "total_energy",          # xantaken * 250 + refills * 150 + energydrinkused * 100 — estimated lifetime energy from items
    "energy_per_day",        # total_energy / real_age — daily energy from items
    "boosters_per_day",      # boostersused / real_age
    "has_se",                # binary: statenhancersused >= 3
]

# Full feature list as seen by the model (must match Ruby's Predictor)
ALL_FEATURES = DB_FEATURE_COLUMNS + ENGINEERED_FEATURES

LABEL_COLUMNS = ["strength", "defense", "speed", "dexterity"]

# Features with heavy-tailed distributions that benefit from log transform
LOG_FEATURES = {
    "xantaken", "energydrinkused", "statenhancersused", "boostersused",
    "lsdtaken", "revives", "exttaken", "victaken", "rehabs",
    "attackswon", "networth", "hospital",
    "total_energy",
}

# Tier boundaries for specialized models
TIERS = [
    ("low",  0,    1e9),   # < 1B
    ("mid",  1e9,  5e9),   # 1B - 5B
    ("high", 5e9,  1e18),  # 5B+
]

MIN_SAMPLES = 100
MIN_TIER_SAMPLES = 50


def add_engineered_features(X, columns):
    """Compute engineered features and append as new columns."""
    col_idx = {name: i for i, name in enumerate(columns)}

    xan = X[:, col_idx["xantaken"]]
    refills = X[:, col_idx["refills"]]
    edrink = X[:, col_idx["energydrinkused"]]
    se = X[:, col_idx["statenhancersused"]]
    boosters = X[:, col_idx["boostersused"]]
    age = np.maximum(X[:, col_idx["real_age"]], 1)  # avoid division by zero

    total_energy = xan * 250 + refills * 150 + edrink * 100

    engineered = np.column_stack([
        xan / age,           # xan_per_day
        refills / age,       # refills_per_day
        edrink / age,        # edrink_per_day
        se / age,            # se_per_day
        total_energy,        # total_energy
        total_energy / age,  # energy_per_day
        boosters / age,      # boosters_per_day
        (se >= 3).astype(np.float32),  # has_se (>=3 to exclude merit-only users)
    ])

    return np.hstack([X, engineered])


def log1p_transform(X, columns):
    """Apply log1p to skewed feature columns (in-place)."""
    for i, col in enumerate(columns):
        if col in LOG_FEATURES:
            X[:, i] = np.log1p(X[:, i])
    return X


def train_and_export(X, y_log, name, output_dir):
    """Train a Random Forest and export to ONNX. Returns the model."""
    model = RandomForestRegressor(
        n_estimators=200,
        max_depth=10,
        min_samples_leaf=10,
        n_jobs=-1,
        random_state=42,
    )
    model.fit(X, y_log)

    scores = cross_val_score(model, X, y_log, cv=5, scoring="r2")
    print(f"  R² (log-space): {scores.mean():.4f} (±{scores.std():.4f})")

    initial_type = [("features", FloatTensorType([None, X.shape[1]]))]
    onnx_model = convert_sklearn(model, initial_types=initial_type)

    output_path = output_dir / f"model_{name}.onnx"
    with open(output_path, "wb") as f:
        f.write(onnx_model.SerializeToString())
    print(f"  Saved to {output_path}")

    return model


def main():
    db_path = sys.argv[1] if len(sys.argv) > 1 else "storage/development.sqlite3"
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("lib/recon")

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    rows = conn.execute(
        f"SELECT {', '.join(DB_FEATURE_COLUMNS + LABEL_COLUMNS)} "
        "FROM recon_training_samples WHERE xantaken IS NOT NULL"
    ).fetchall()
    conn.close()

    if len(rows) < MIN_SAMPLES:
        print(f"Only {len(rows)} samples (need {MIN_SAMPLES}). Skipping.", file=sys.stderr)
        sys.exit(1)

    X = np.array([[max(row[col] or 0, 0) for col in DB_FEATURE_COLUMNS] for row in rows], dtype=np.float32)
    y = np.array([max(sum(row[col] or 0 for col in LABEL_COLUMNS), 0) for row in rows], dtype=np.float32)

    n_before = len(y)

    # Remove zero-stat samples (missing spy data, not real zeroes)
    nonzero = y > 0
    X, y = X[nonzero], y[nonzero]

    # Remove extremely unbalanced builds (one stat >95% of total) — likely data errors
    stats = np.array([[max(row[col] or 0, 0) for col in LABEL_COLUMNS] for row in rows], dtype=np.float32)
    stats = stats[nonzero]
    max_stat_ratio = stats.max(axis=1) / np.maximum(y, 1)
    balanced = max_stat_ratio <= 0.95
    X, y = X[balanced], y[balanced]

    # Remove outliers: clip top/bottom 1% by log(total_stats)
    y_log_raw = np.log1p(y)
    p1, p99 = np.percentile(y_log_raw, 1), np.percentile(y_log_raw, 99)
    in_range = (y_log_raw >= p1) & (y_log_raw <= p99)
    X, y = X[in_range], y[in_range]

    n_removed = n_before - len(y)
    print(f"Removed {n_removed} samples ({n_removed*100/n_before:.1f}%): "
          f"zero-stat, unbalanced, or outlier")

    # Add engineered features before transforms
    X = add_engineered_features(X, DB_FEATURE_COLUMNS)

    # Log-transform skewed features
    X = log1p_transform(X, ALL_FEATURES)

    # Log-transform target (inverse in Ruby via exp)
    y_log = np.log1p(y)

    output_dir.mkdir(parents=True, exist_ok=True)

    # Train global model (used for routing)
    print(f"\n=== Global model ({len(y)} samples, {len(ALL_FEATURES)} features) ===")
    global_model = train_and_export(X, y_log, "global", output_dir)

    importances = sorted(
        zip(ALL_FEATURES, global_model.feature_importances_), key=lambda x: -x[1]
    )
    print("  Top features:")
    for name, imp in importances[:10]:
        print(f"    {name}: {imp:.4f}")

    # Train tier-specific models
    for tier_name, lo, hi in TIERS:
        tier_mask = (y >= lo) & (y < hi)
        n_tier = tier_mask.sum()

        if n_tier < MIN_TIER_SAMPLES:
            print(f"\n=== Tier '{tier_name}' — skipped ({n_tier} samples, need {MIN_TIER_SAMPLES}) ===")
            continue

        print(f"\n=== Tier '{tier_name}' ({n_tier} samples) ===")
        train_and_export(X[tier_mask], y_log[tier_mask], tier_name, output_dir)

    print("\nDone!")


if __name__ == "__main__":
    main()
