class RemoveGenderFromTornUser < ActiveRecord::Migration[8.1]
  def change
    remove_column :torn_users, :gender, :string
  end
end
