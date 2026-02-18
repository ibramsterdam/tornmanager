class CreateRankedWars < ActiveRecord::Migration[8.1]
  def change
    create_table :ranked_wars do |t|
      t.integer :torn_war_id, null: false
      t.references :faction, null: false, foreign_key: true
      t.integer :opponent_faction_id, null: false
      t.string :opponent_faction_name, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.integer :target_score, null: false
      t.integer :our_score, default: 0, null: false
      t.integer :their_score, default: 0, null: false
      t.integer :winner_faction_id
      t.boolean :forfeit, default: false, null: false
      t.integer :our_attacks, default: 0, null: false
      t.integer :their_attacks, default: 0, null: false
      t.string :rank_before
      t.string :rank_after
      t.integer :respect_gained, default: 0, null: false
      t.integer :points_gained, default: 0, null: false
      t.json :our_members, default: []
      t.json :their_members, default: []
      t.json :our_rewards, default: {}
      t.json :their_rewards, default: {}

      t.timestamps
    end

    add_index :ranked_wars, :torn_war_id, unique: true
    add_index :ranked_wars, [ :faction_id, :started_at ]
  end
end
