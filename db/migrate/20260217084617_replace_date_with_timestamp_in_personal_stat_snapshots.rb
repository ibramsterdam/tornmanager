class ReplaceDateWithTimestampInPersonalStatSnapshots < ActiveRecord::Migration[8.1]
  def up
    # Backfill timestamp from date for existing records
    execute <<-SQL
      UPDATE personal_stat_snapshots
      SET timestamp = CAST(strftime('%s', date || ' 12:00:00') AS INTEGER)
      WHERE timestamp IS NULL AND date IS NOT NULL
    SQL

    # Remove old index on date
    remove_index :personal_stat_snapshots, [ :user_id, :date ], if_exists: true

    # Remove date column
    remove_column :personal_stat_snapshots, :date, :date

    # Make timestamp non-null and add unique index
    change_column_null :personal_stat_snapshots, :timestamp, false
    add_index :personal_stat_snapshots, [ :user_id, :timestamp ], unique: true
  end

  def down
    remove_index :personal_stat_snapshots, [ :user_id, :timestamp ]
    change_column_null :personal_stat_snapshots, :timestamp, true
    add_column :personal_stat_snapshots, :date, :date

    execute <<-SQL
      UPDATE personal_stat_snapshots
      SET date = DATE(timestamp, 'unixepoch')
      WHERE timestamp IS NOT NULL
    SQL

    add_index :personal_stat_snapshots, [ :user_id, :date ], unique: true
  end
end
