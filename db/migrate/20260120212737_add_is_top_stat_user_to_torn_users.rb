class AddIsTopStatUserToTornUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :torn_users, :hof_stats_user, :boolean, null: false, default: false
    add_index :torn_users, :hof_stats_user
  end
end
