class AddChannelIdsToEliminationSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :elimination_settings, :alerts_channel_id, :string
    add_column :elimination_settings, :standings_channel_id, :string
  end
end
