class AddBackfillEndsAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :backfill_ends_at, :datetime
  end
end
