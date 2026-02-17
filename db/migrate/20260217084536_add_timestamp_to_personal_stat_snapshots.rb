class AddTimestampToPersonalStatSnapshots < ActiveRecord::Migration[8.1]
  def change
    add_column :personal_stat_snapshots, :timestamp, :integer
  end
end
