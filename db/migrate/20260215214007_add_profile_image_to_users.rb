class AddProfileImageToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :profile_image, :string
  end
end
