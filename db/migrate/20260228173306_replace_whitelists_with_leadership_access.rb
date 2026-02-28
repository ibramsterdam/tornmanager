class ReplaceWhitelistsWithLeadershipAccess < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :leadership_access, :boolean, default: false, null: false

    # Backfill from faction_whitelists
    execute <<~SQL
      UPDATE users
      SET leadership_access = 1
      WHERE id IN (SELECT user_id FROM faction_whitelists)
    SQL

    drop_table :faction_whitelists
  end

  def down
    create_table :faction_whitelists do |t|
      t.references :faction, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :faction_whitelists, [ :faction_id, :user_id ], unique: true

    # Backfill from leadership_access
    execute <<~SQL
      INSERT INTO faction_whitelists (faction_id, user_id, created_at, updated_at)
      SELECT faction_id, id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM users
      WHERE leadership_access = 1 AND faction_id IS NOT NULL
    SQL

    remove_column :users, :leadership_access
  end
end
