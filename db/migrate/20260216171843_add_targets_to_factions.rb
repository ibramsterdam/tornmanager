class AddTargetsToFactions < ActiveRecord::Migration[8.1]
  def change
    add_column :factions, :xanax_target, :decimal, default: 2.5, null: false
    add_column :factions, :energy_refill_target, :decimal, default: 1.0, null: false
    add_column :factions, :nerve_refill_target, :decimal, default: 1.0, null: false
  end
end
