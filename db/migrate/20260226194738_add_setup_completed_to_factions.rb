class AddSetupCompletedToFactions < ActiveRecord::Migration[8.1]
  def change
    add_column :factions, :setup_completed, :boolean, default: true, null: false
  end
end
