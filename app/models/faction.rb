class Faction < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :faction_subscription_grants, dependent: :nullify
  has_many :ranked_wars, dependent: :destroy
  has_one :faction_setting, dependent: :destroy
  has_many :spy_reports, dependent: :destroy

  validates :torn_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :xanax_target, presence: true, numericality: { greater_than: 0 }
  validates :energy_refill_target, presence: true, numericality: { greater_than: 0 }
  validates :nerve_refill_target, presence: true, numericality: { greater_than: 0 }

  scope :tracked, -> { where(track_stats: true) }

  # Use torn_id in URLs instead of database id
  def to_param
    torn_id.to_s
  end

  def member_count
    users.count
  end

  # Backfill status
  def backfill_in_progress?
    backfill_ends_at.present? && backfill_ends_at > Time.current
  end

  def backfill_seconds_remaining
    return 0 unless backfill_in_progress?
    (backfill_ends_at - Time.current).to_i
  end

  def clear_backfill_status!
    update!(backfill_ends_at: nil, backfill_target_date: nil)
  end
end
