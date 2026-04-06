class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def up
    create_table :subscriptions do |t|
      t.string :subscribable_type, null: false
      t.integer :subscribable_id, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :subscriptions, [ :subscribable_type, :subscribable_id ], unique: true

    # Create faction subscriptions for all factions with setup_completed: true
    Faction.where(setup_completed: true).find_each do |faction|
      execute <<-SQL
        INSERT INTO subscriptions (subscribable_type, subscribable_id, expires_at, created_at, updated_at)
        VALUES ('Faction', #{faction.id}, '#{1.month.from_now.utc.strftime('%Y-%m-%d %H:%M:%S')}', '#{Time.current.utc.strftime('%Y-%m-%d %H:%M:%S')}', '#{Time.current.utc.strftime('%Y-%m-%d %H:%M:%S')}')
      SQL
    end

    # Wipe all user subscription_expires_at (keeping the column for backwards compat)
    execute "UPDATE users SET subscription_expires_at = NULL"
  end

  def down
    drop_table :subscriptions
  end
end
