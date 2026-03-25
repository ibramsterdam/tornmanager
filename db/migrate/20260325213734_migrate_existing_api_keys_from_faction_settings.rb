class MigrateExistingApiKeysFromFactionSettings < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO api_keys (faction_id, type, key, access_type, faction_access, created_at, updated_at)
      SELECT faction_id, 'ApiKey::Torn', torn_api_key, torn_api_access_type, false, created_at, updated_at
      FROM faction_settings
      WHERE torn_api_key IS NOT NULL AND torn_api_key != ''
    SQL

    execute <<~SQL
      INSERT INTO api_keys (faction_id, type, key, access_type, faction_access, created_at, updated_at)
      SELECT faction_id, 'ApiKey::Tornstats', tornstats_api_key, NULL, false, created_at, updated_at
      FROM faction_settings
      WHERE tornstats_api_key IS NOT NULL AND tornstats_api_key != ''
    SQL
  end

  def down
    execute "DELETE FROM api_keys"
  end
end
