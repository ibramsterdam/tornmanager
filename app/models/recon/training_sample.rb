class Recon::TrainingSample < ApplicationRecord
  self.table_name = "recon_training_samples"

  FEATURE_COLUMNS = %w[
    xantaken energydrinkused refills daysbeendonator
    statenhancersused boostersused lsdtaken revives exttaken victaken
    rehabs highestbeaten hospital jobpointsused trainsreceived
    attackswon awards useractivity networth level property_happy real_age
  ].freeze

  LABEL_COLUMNS = %w[strength defense speed dexterity].freeze

  validates :player_id, presence: true
  validates :strength, presence: true
  validates :defense, presence: true
  validates :speed, presence: true
  validates :dexterity, presence: true
  validates :spied_at, presence: true

  def total_stats
    strength + defense + speed + dexterity
  end

  def features
    FEATURE_COLUMNS.index_with { |col| self[col] }
  end
end
