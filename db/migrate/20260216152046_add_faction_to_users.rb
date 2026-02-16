class AddFactionToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :faction, null: true, foreign_key: true
  end
end
