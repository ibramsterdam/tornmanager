class CreateFactionSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :faction_settings do |t|
      t.references :faction, null: false, foreign_key: true, index: { unique: true }
      t.string :torn_api_key
      t.string :tornstats_api_key

      t.timestamps
    end
  end
end
