class AddFactionTornIdsForRecruiter < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :faction_torn_id, :integer
    add_column :companies, :director_faction_torn_id, :integer
  end
end
