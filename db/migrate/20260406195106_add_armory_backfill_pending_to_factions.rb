class AddArmoryBackfillPendingToFactions < ActiveRecord::Migration[8.1]
  def change
    add_column :factions, :armory_backfill_pending, :boolean, default: false, null: false
  end
end
