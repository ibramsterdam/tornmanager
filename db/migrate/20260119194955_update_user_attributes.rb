class UpdateUserAttributes < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :torn_id
    add_reference :users, :torn_user, foreign_key: true, null: true

    remove_column :users, :torn_id, :integer
    remove_column :users, :level, :integer
    remove_column :users, :name, :string
    remove_column :users, :gender, :string
  end
end
