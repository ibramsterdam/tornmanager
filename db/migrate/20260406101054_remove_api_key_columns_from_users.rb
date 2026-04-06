class RemoveApiKeyColumnsFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :api_key
    remove_column :users, :api_key, :string
    remove_column :users, :api_access_type, :string
  end
end
