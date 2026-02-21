class CreateFactionWhitelists < ActiveRecord::Migration[8.1]
  def change
    create_table :faction_whitelists do |t|
      t.references :faction, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :faction_whitelists, [ :faction_id, :user_id ], unique: true
  end
end
