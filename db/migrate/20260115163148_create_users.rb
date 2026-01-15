class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :api_key, null: false
      t.integer :torn_id, null: false
      t.integer :level, null: false
      t.string :name, null: false
      t.string :gender, null: false

      t.timestamps
    end
    add_index :users, :api_key, unique: true
    add_index :users, :torn_id, unique: true
  end
end
