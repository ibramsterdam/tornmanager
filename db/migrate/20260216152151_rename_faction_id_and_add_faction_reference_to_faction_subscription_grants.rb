class RenameFactionIdAndAddFactionReferenceToFactionSubscriptionGrants < ActiveRecord::Migration[8.1]
  def change
    # Rename existing faction_id (torn faction ID) to torn_faction_id
    rename_column :faction_subscription_grants, :faction_id, :torn_faction_id
    rename_index :faction_subscription_grants, "index_faction_subscription_grants_on_faction_id", "index_faction_subscription_grants_on_torn_faction_id"

    # Add reference to factions table
    add_reference :faction_subscription_grants, :faction, null: true, foreign_key: true
  end
end
