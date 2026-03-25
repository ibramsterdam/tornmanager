class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.references :faction, null: false, foreign_key: true
      t.string :type, null: false
      t.string :key, null: false
      t.string :access_type
      t.boolean :faction_access, default: false, null: false

      t.timestamps
    end

    add_index :api_keys, [ :faction_id, :type ], unique: true
  end
end
