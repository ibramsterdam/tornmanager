class RemoveApiKeyColumnsFromFactionSettings < ActiveRecord::Migration[8.1]
  def change
    remove_column :faction_settings, :torn_api_key, :string
    remove_column :faction_settings, :torn_api_access_type, :string
    remove_column :faction_settings, :tornstats_api_key, :string
  end
end
