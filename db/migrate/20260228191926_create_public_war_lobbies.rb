class CreatePublicWarLobbies < ActiveRecord::Migration[8.1]
  def change
    create_table :public_war_lobbies do |t|
      t.string :slug, null: false
      t.integer :faction_torn_id, null: false
      t.string :faction_name, null: false
      t.string :opponent_faction_name, null: false
      t.string :created_by_name, null: false
      t.integer :created_by_torn_id, null: false
      t.string :password_digest

      t.timestamps
    end
    add_index :public_war_lobbies, :slug, unique: true
  end
end
