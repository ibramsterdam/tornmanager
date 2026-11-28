class AddDirectorActivity < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_action_at, :datetime
    add_column :companies, :director_torn_id, :integer
    add_index :companies, :director_torn_id
  end
end
