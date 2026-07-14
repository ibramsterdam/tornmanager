class AddAdminStatsIndexes < ActiveRecord::Migration[8.1]
  def change
    # Per-key aggregations (admin stats breakdown, peak rates) previously
    # full-scanned api_calls once per key.
    add_index :api_calls, [ :api_key, :created_at ]

    # Global min/max/range queries on a ~3.8M-row table; the existing
    # composite (faction_id, recorded_at) can't serve them.
    add_index :member_activity_snapshots, :recorded_at

    # Global earliest/latest on admin stats and the retention cleanup's
    # `occurred_at < cutoff` delete.
    add_index :armory_news_entries, :occurred_at
  end
end
