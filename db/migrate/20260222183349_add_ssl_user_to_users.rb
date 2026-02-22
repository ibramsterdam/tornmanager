class AddSslUserToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ssl_user, :boolean, default: false, null: false
  end
end
