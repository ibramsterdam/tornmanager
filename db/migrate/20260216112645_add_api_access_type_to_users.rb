class AddApiAccessTypeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :api_access_type, :string
  end
end
