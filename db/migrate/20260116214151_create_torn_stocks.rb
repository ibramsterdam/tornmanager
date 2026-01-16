class CreateTornStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :torn_stocks do |t|
      t.integer :torn_id, null: false
      t.string :name, null: false
      t.string :acronym, null: false
      t.decimal :current_price, null: false
      t.integer :dividend_frequency
      t.integer :dividend_requirement, null: false
      t.string :dividend_description, null: false
      t.integer :dividend_value, :integer, default: 0, null: false

      t.timestamps
    end
    add_index :torn_stocks, :torn_id, unique: true
  end
end
