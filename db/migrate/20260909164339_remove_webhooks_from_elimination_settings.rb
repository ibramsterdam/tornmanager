class RemoveWebhooksFromEliminationSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :elimination_settings, :alerts_webhook_url, :string
    remove_column :elimination_settings, :standings_webhook_url, :string
    remove_column :elimination_settings, :standings_channel_id, :string
  end
end
