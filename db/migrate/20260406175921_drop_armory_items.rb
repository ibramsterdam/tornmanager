class DropArmoryItems < ActiveRecord::Migration[8.1]
  def up
    drop_table :armory_items
  end

  def down
    create_table :armory_items do |t|
      t.references :faction, null: false, foreign_key: true
      t.integer :torn_item_id, null: false
      t.bigint :uid
      t.string :name, null: false
      t.string :category, null: false
      t.string :item_type
      t.integer :quantity, default: 1
      t.integer :available, default: 0
      t.integer :loaned, default: 0
      t.text :loaned_to
      t.decimal :damage
      t.decimal :accuracy
      t.decimal :armor_rating
      t.decimal :quality
      t.string :rarity
      t.json :bonuses, default: []

      t.timestamps
    end

    add_index :armory_items, [ :faction_id, :torn_item_id ]
    add_index :armory_items, [ :faction_id, :uid ], unique: true
  end
end
