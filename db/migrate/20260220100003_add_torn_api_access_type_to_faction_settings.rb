class AddTornApiAccessTypeToFactionSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :faction_settings, :torn_api_access_type, :string
  end
end
