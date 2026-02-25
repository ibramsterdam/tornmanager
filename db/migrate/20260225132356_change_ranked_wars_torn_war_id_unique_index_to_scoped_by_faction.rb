class ChangeRankedWarsTornWarIdUniqueIndexToScopedByFaction < ActiveRecord::Migration[8.1]
  def change
    remove_index :ranked_wars, :torn_war_id, unique: true
    add_index :ranked_wars, [ :faction_id, :torn_war_id ], unique: true
  end
end
