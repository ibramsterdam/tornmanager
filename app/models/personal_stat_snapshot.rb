class PersonalStatSnapshot < ApplicationRecord
  belongs_to :user

  validates :date, presence: true, uniqueness: { scope: :user_id }

  # Rows missing any tracked stat: written before a column existed, or a
  # batch-2 fetch that never completed. The nightly gap scan re-fetches these
  # the same as fully missing dates. Tombstoned rows (Torn has no data for
  # that player/date) are excluded — re-fetching them can never succeed.
  scope :partial, -> {
    TRACKED_STATS.values.map { |column| where(column => nil) }.reduce(:or)
      .where(torn_data_missing: false)
  }

  def self.tracking_start_date
    Date.new(2026, 1, 1)
  end

  def self.tracking_end_date
    Date.current.yesterday
  end

  TRACKED_STATS_BATCH_1 = {
    "xantaken" => :drugs_xanax,
    "energydrinkused" => :items_used_energy_drinks,
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
