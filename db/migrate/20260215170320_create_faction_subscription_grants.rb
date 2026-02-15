class CreateFactionSubscriptionGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :faction_subscription_grants do |t|
      t.integer :faction_id, null: false
      t.string :faction_name, null: false
      t.integer :weeks_granted, null: false
      t.references :granted_by, null: false, foreign_key: { to_table: :users }
      t.datetime :granted_at, null: false

      t.timestamps
    end

    add_index :faction_subscription_grants, :faction_id
  end
end
