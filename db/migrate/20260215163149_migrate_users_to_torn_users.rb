class MigrateUsersToTornUsers < ActiveRecord::Migration[8.1]
  def up
    # Copy api_key from users to torn_users
    execute <<-SQL
      UPDATE torn_users
      SET api_key = users.api_key
      FROM users
      WHERE torn_users.id = users.torn_user_id
    SQL

    # Make api_key unique (but allow null)
    remove_index :torn_users, :api_key
    add_index :torn_users, :api_key, unique: true, where: "api_key IS NOT NULL"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
