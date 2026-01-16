class CreateTornItems < ActiveRecord::Migration[8.1]
  def change
    create_table :torn_items do |t|
      t.integer :torn_id, null: false
      t.string :name, null: false
      t.integer :market_price

      t.timestamps
    end

    add_index :torn_items, :torn_id, unique: true
  end
end
