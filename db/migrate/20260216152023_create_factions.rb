class CreateFactions < ActiveRecord::Migration[8.1]
  def change
    create_table :factions do |t|
      t.integer :torn_id, null: false
      t.string :name, null: false
      t.boolean :track_stats, default: false, null: false

      t.timestamps
    end
    add_index :factions, :torn_id, unique: true
    add_index :factions, :track_stats
  end
end
