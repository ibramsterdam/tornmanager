class RemoveUserIdFromTornUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :torn_users, :user_id, :integer
  end
end
