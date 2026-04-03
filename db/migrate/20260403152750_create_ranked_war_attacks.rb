class CreateRankedWarAttacks < ActiveRecord::Migration[8.1]
  def change
    create_table :ranked_war_attacks do |t|
      t.references :ranked_war, null: false, foreign_key: true
      t.integer :torn_attack_id, null: false
      t.string :code

      # Attacker
      t.integer :attacker_id, null: false
      t.string :attacker_name
      t.integer :attacker_level
      t.integer :attacker_faction_id
      t.string :attacker_faction_name

      # Defender
      t.integer :defender_id, null: false
      t.string :defender_name
      t.integer :defender_level
      t.integer :defender_faction_id
      t.string :defender_faction_name

      # Timing
      t.integer :started, null: false
      t.integer :ended, null: false

      # Result
      t.string :result, null: false
      t.float :respect_gain, default: 0
      t.float :respect_loss, default: 0
      t.integer :chain, default: 0

      # Flags
      t.boolean :is_stealthed, default: false
      t.boolean :is_interrupted, default: false
      t.boolean :is_raid, default: false

      # Modifiers
      t.float :fair_fight
      t.float :war
      t.float :retaliation
      t.float :group_modifier
      t.float :overseas
      t.float :chain_modifier
      t.float :warlord

      # Effects
      t.json :finishing_hit_effects, default: []

      t.timestamps
    end

    add_index :ranked_war_attacks, [ :ranked_war_id, :torn_attack_id ], unique: true
    add_index :ranked_war_attacks, :attacker_id
    add_index :ranked_war_attacks, :defender_id
  end
end
