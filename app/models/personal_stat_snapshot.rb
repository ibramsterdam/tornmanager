class PersonalStatSnapshot < ApplicationRecord
  belongs_to :user

  validates :date, presence: true, uniqueness: { scope: :user_id }

  TRACKING_START_DATE = Date.new(2026, 1, 1).freeze

  def self.tracking_end_date
    Date.current.yesterday
  end

  # Central definition of stats we track - maps API stat name to DB column
  # Split into batches of max 10 due to Torn API v2 limit
  TRACKED_STATS_BATCH_1 = {
    "xantaken" => :drugs_xanax,
    "cantaken" => :drugs_cannabis,
    "refills" => :other_refills_energy,
    "nerverefills" => :other_refills_nerve,
    "boostersused" => :items_used_boosters,
    "statenhancersused" => :items_used_stat_enhancers,
    "contractscompleted" => :missions_contracts_total,
    "criminaloffenses" => :crimes_offenses_total,
    "timeplayed" => :other_activity_time,
    "networth" => :networth_total
  }.freeze

  TRACKED_STATS_BATCH_2 = {
    "moneymugged" => :attacking_networth_money_mugged
  }.freeze

  TRACKED_STATS = TRACKED_STATS_BATCH_1.merge(TRACKED_STATS_BATCH_2).freeze

  def self.api_stat_names
    TRACKED_STATS.keys
  end

  def self.db_columns
    TRACKED_STATS.values
  end

  def self.stat_batches
    [ TRACKED_STATS_BATCH_1, TRACKED_STATS_BATCH_2 ]
  end
end
