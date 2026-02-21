class ChangeDefaultTargetsOnFactions < ActiveRecord::Migration[8.1]
  def change
    change_column_default :factions, :energy_refill_target, from: 1.0, to: 0.0
    change_column_default :factions, :nerve_refill_target, from: 1.0, to: 0.0
    change_column_default :factions, :track_stats, from: false, to: true
  end
end
