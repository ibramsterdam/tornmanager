class AddEmploymentToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :company_id, :integer
    add_column :users, :company_director, :boolean, null: false, default: false
    add_column :users, :company_synced_at, :datetime
    add_column :users, :working_stats, :bigint
    add_column :users, :working_stats_at, :datetime
    add_index :users, :company_id
    add_index :users, :working_stats
  end
end
