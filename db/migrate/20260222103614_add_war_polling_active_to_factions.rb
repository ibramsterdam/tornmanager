class AddWarPollingActiveToFactions < ActiveRecord::Migration[8.1]
  def change
    add_column :factions, :war_polling_active, :boolean, default: false, null: false
  end
end
