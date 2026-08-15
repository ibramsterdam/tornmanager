class AddBannedReasonToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :banned_reason, :string
  end
end
