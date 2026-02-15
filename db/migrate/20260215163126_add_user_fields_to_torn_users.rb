class AddUserFieldsToTornUsers < ActiveRecord::Migration[8.1]
  def change
    # Add user authentication field to torn_users
    add_column :torn_users, :api_key, :string

    # Add index (will be unique after migration)
    add_index :torn_users, :api_key
  end
end
