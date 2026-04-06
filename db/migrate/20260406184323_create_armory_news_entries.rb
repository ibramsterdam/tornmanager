class CreateArmoryNewsEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :armory_news_entries do |t|
      t.references :faction, null: false, foreign_key: true
      t.string :torn_news_id, null: false
      t.integer :player_id
      t.string :player_name
      t.string :action, null: false
      t.string :item
      t.text :text
      t.datetime :occurred_at, null: false
      t.datetime :created_at, null: false
    end

    add_index :armory_news_entries, [ :faction_id, :torn_news_id ], unique: true
    add_index :armory_news_entries, [ :faction_id, :occurred_at ]
    add_index :armory_news_entries, [ :faction_id, :player_id, :action ]
  end
end
