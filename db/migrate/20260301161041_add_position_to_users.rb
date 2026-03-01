class AddPositionToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :position, :string
  end
end
