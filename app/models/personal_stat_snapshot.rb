class PersonalStatSnapshot < ApplicationRecord
  belongs_to :user

  validates :timestamp, presence: true
  validate :one_snapshot_per_day_per_user, on: :create

  # Central definition of stats we track - maps API stat name to DB column
  TRACKED_STATS = {
    "xantaken" => :drugs_xanax,
    "cantaken" => :drugs_cannabis,
    "refills" => :other_refills_energy,
    "nerverefills" => :other_refills_nerve,
    "boostersused" => :items_used_boosters,
    "statenhancersused" => :items_used_stat_enhancers,
    "contractscompleted" => :missions_contracts_total,
    "criminaloffenses" => :crimes_offenses_total,
    "timeplayed" => :other_activity_time,
    "networth" => :networth_total,
    "moneymugged" => :attacking_networth_money_mugged
  }.freeze

  def self.api_stat_names
    TRACKED_STATS.keys
  end

  def self.db_columns
    TRACKED_STATS.values
  end

  def date
    Time.at(timestamp).utc.to_date if timestamp
  end

  private

  def one_snapshot_per_day_per_user
    return unless timestamp && user_id

    day_start = date.beginning_of_day.to_i
    day_end = date.end_of_day.to_i

    existing = self.class.where(user_id: user_id, timestamp: day_start..day_end)
    existing = existing.where.not(id: id) if persisted?

    if existing.exists?
      errors.add(:timestamp, "already has a snapshot for #{date}")
    end
  end
end
