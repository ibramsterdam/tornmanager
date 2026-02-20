class CreateSpyReports < ActiveRecord::Migration[8.1]
  def change
    create_table :spy_reports do |t|
      t.references :faction, null: false, foreign_key: true
      t.integer :torn_id, null: false
      t.bigint :strength
      t.bigint :defense
      t.bigint :speed
      t.bigint :dexterity
      t.bigint :total
      t.datetime :spied_at

      t.timestamps
    end

    add_index :spy_reports, [ :faction_id, :torn_id ], unique: true
    add_index :spy_reports, :torn_id
  end
end
