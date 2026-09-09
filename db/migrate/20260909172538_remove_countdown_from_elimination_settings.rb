class RemoveCountdownFromEliminationSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :elimination_settings, :countdown_bottom_ranks, :integer, null: false, default: 2
    remove_column :elimination_settings, :notify_countdown, :boolean, null: false, default: true
    remove_column :elimination_settings, :life_ticks_from, :datetime, null: false, default: Time.utc(2026, 9, 11, 12)
  end
end
