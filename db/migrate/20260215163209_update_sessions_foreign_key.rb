class UpdateSessionsForeignKey < ActiveRecord::Migration[8.1]
  def up
    # Add new foreign key to torn_users
    add_column :sessions, :torn_user_id, :integer

    # Copy user_id to torn_user_id via the users table
    execute <<-SQL
      UPDATE sessions
      SET torn_user_id = users.torn_user_id
      FROM users
      WHERE sessions.user_id = users.id
    SQL

    # Delete orphaned sessions (where torn_user_id is still null)
    execute "DELETE FROM sessions WHERE torn_user_id IS NULL"

    # Make torn_user_id not null and add index
    change_column_null :sessions, :torn_user_id, false
    add_index :sessions, :torn_user_id

    # Remove old foreign key and column
    remove_foreign_key :sessions, :users
    remove_index :sessions, :user_id
    remove_column :sessions, :user_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
