class RemoveTrackStatsFromFactions < ActiveRecord::Migration[8.1]
  def change
    remove_index :factions, :track_stats
    remove_column :factions, :track_stats, :boolean, default: true, null: false
  end
end
