class AddBackfillTrackingToFactions < ActiveRecord::Migration[8.1]
  def change
    add_column :factions, :backfill_started_at, :datetime
    add_column :factions, :backfill_ends_at, :datetime
    add_column :factions, :backfill_target_date, :date
  end
end
