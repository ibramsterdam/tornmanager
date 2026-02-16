class AddDateToPersonalStatSnapshots < ActiveRecord::Migration[8.1]
  def change
    add_column :personal_stat_snapshots, :date, :date

    # Backfill date from created_at for existing records
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE personal_stat_snapshots
          SET date = DATE(created_at)
        SQL

        # Delete duplicate snapshots, keeping only the latest one per user per day
        execute <<-SQL
          DELETE FROM personal_stat_snapshots
          WHERE id NOT IN (
            SELECT MAX(id)
            FROM personal_stat_snapshots
            GROUP BY user_id, date
          )
        SQL
      end
    end

    add_index :personal_stat_snapshots, [ :user_id, :date ], unique: true
  end
end
