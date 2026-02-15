class CreateFactionGrantUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :faction_grant_users do |t|
      t.references :faction_subscription_grant, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :faction_grant_users, [ :faction_subscription_grant_id, :user_id ], unique: true, name: "index_faction_grant_users_on_grant_and_user"
  end
end
