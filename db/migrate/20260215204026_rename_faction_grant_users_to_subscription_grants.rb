class RenameFactionGrantUsersToSubscriptionGrants < ActiveRecord::Migration[8.1]
  def change
    rename_table :faction_grant_users, :subscription_grants
  end
end
