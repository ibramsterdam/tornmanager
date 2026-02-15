class RenameTornUsersToUsers < ActiveRecord::Migration[8.1]
  def change
    rename_table :torn_users, :users

    # Rename foreign key columns in related tables
    rename_column :sessions, :torn_user_id, :user_id
    rename_column :personal_stat_snapshots, :torn_user_id, :user_id

    # Update foreign key constraints (remove old, add new)
    remove_foreign_key :personal_stat_snapshots, :torn_users if foreign_key_exists?(:personal_stat_snapshots, :torn_users)
    add_foreign_key :personal_stat_snapshots, :users
    add_foreign_key :sessions, :users
  end
end
