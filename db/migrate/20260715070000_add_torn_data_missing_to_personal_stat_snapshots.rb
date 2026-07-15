class AddTornDataMissingToPersonalStatSnapshots < ActiveRecord::Migration[8.1]
  def change
    # Tombstone flag: Torn has no personalstats for this user/date (account
    # inactive or nonexistent then). Stops the nightly gap scan from
    # re-fetching the same unfillable dates forever.
    add_column :personal_stat_snapshots, :torn_data_missing, :boolean, default: false, null: false
  end
end
