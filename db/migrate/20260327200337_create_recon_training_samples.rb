class CreateReconTrainingSamples < ActiveRecord::Migration[8.1]
  def change
    create_table :recon_training_samples do |t|
      t.integer :player_id, null: false

      # Labels (from spy reports)
      t.bigint :strength, null: false
      t.bigint :defense, null: false
      t.bigint :speed, null: false
      t.bigint :dexterity, null: false

      # Features: Tier 1 - Direct energy sources
      t.integer :xantaken
      t.integer :energydrinkused
      t.integer :refills
      t.integer :daysbeendonator

      # Features: Tier 2 - Training multipliers & optimization
      t.integer :statenhancersused
      t.integer :boostersused
      t.integer :lsdtaken
      t.integer :revives
      t.integer :exttaken
      t.integer :victaken
      t.integer :rehabs
      t.integer :highestbeaten
      t.integer :hospital
      t.integer :jobpointsused
      t.integer :trainsreceived

      # Features: Tier 3 - Progression & activity proxies
      t.integer :attackswon
      t.integer :awards
      t.integer :useractivity
      t.bigint :networth
      t.integer :level
      t.integer :property_happy
      t.integer :real_age

      # Metadata
      t.datetime :spied_at, null: false

      t.timestamps
    end

    add_index :recon_training_samples, :player_id
    add_index :recon_training_samples, :spied_at
  end
end
