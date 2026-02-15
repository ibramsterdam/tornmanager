class AddIndexToSubscriptionExpiresAt < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :subscription_expires_at
  end
end
