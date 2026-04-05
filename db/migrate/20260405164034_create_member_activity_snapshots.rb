class CreateMemberActivitySnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :member_activity_snapshots do |t|
      t.references :faction, null: false, foreign_key: true
      t.integer :torn_member_id, null: false
      t.string :member_name, null: false
      t.datetime :recorded_at, null: false
      t.integer :hour_utc, null: false
      t.integer :day_of_week, null: false
      t.string :status, null: false

      t.timestamps
    end

    add_index :member_activity_snapshots, [ :faction_id, :recorded_at ]
    add_index :member_activity_snapshots, [ :faction_id, :torn_member_id, :recorded_at ],
              name: "idx_activity_faction_member_time"
    add_index :member_activity_snapshots, [ :faction_id, :hour_utc, :day_of_week ],
              name: "idx_activity_heatmap"
  end
end
