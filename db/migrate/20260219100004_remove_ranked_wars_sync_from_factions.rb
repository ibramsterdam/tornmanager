class RemoveRankedWarsSyncFromFactions < ActiveRecord::Migration[8.1]
  def change
    remove_column :factions, :ranked_wars_sync_ends_at, :datetime
  end
end
