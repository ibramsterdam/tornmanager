class AddUserIdToApiKeys < ActiveRecord::Migration[8.1]
  def up
    # Add user_id column (nullable, since faction keys don't have a user)
    add_column :api_keys, :user_id, :integer
    add_index :api_keys, [ :user_id, :type ], unique: true, where: "user_id IS NOT NULL", name: "index_api_keys_on_user_id_and_type"

    # Make faction_id nullable
    change_column_null :api_keys, :faction_id, true

    # Migrate existing user api_key data into ApiKey::Torn records
    execute <<~SQL
      INSERT INTO api_keys (key, access_type, type, user_id, faction_access, created_at, updated_at)
      SELECT api_key, api_access_type, 'ApiKey::Torn', id, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM users
      WHERE api_key IS NOT NULL
    SQL
  end

  def down
    # Copy user keys back to users table
    execute <<~SQL
      UPDATE users
      SET api_key = (
        SELECT api_keys.key FROM api_keys
        WHERE api_keys.user_id = users.id AND api_keys.type = 'ApiKey::Torn' AND api_keys.faction_id IS NULL
      ),
      api_access_type = (
        SELECT api_keys.access_type FROM api_keys
        WHERE api_keys.user_id = users.id AND api_keys.type = 'ApiKey::Torn' AND api_keys.faction_id IS NULL
      )
    SQL

    # Remove user api keys from api_keys table
    execute "DELETE FROM api_keys WHERE user_id IS NOT NULL AND faction_id IS NULL"

    remove_index :api_keys, name: "index_api_keys_on_user_id_and_type"
    remove_column :api_keys, :user_id

    change_column_null :api_keys, :faction_id, false
  end
end
