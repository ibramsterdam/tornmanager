class RemoveBackfillStartedAtFromFactions < ActiveRecord::Migration[8.1]
  def change
    remove_column :factions, :backfill_started_at, :datetime
  end
end
