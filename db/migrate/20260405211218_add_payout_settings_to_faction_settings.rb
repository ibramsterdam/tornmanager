class AddPayoutSettingsToFactionSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :faction_settings, :payout_faction_cut, :decimal, default: 10, null: false
    add_column :faction_settings, :payout_assist_value, :decimal, default: 0.75, null: false
  end
end
