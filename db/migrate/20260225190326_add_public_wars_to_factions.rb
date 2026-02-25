class AddPublicWarsToFactions < ActiveRecord::Migration[8.1]
  def change
    add_column :factions, :public_wars, :boolean, default: false, null: false
  end
end
