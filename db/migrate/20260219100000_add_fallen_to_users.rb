class AddFallenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :fallen, :boolean, default: false, null: false
  end
end
