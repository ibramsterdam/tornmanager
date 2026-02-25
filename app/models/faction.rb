class Faction < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :faction_subscription_grants, dependent: :nullify
  has_many :ranked_wars, dependent: :destroy
  has_one :faction_setting, dependent: :destroy
  has_many :spy_reports, dependent: :destroy
  has_many :faction_whitelists, dependent: :destroy
  has_many :whitelisted_users, through: :faction_whitelists, source: :user

  validates :torn_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :xanax_target, presence: true, numericality: { greater_than: 0 }
  validates :energy_refill_target, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :nerve_refill_target, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :tracked, -> { where(track_stats: true) }

  def to_param
    torn_id.to_s
  end

  def member_count
    users.count
  end

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

  def current_war
    ranked_wars.ongoing.order(started_at: :desc).first
  end

  def start_war_polling!
    update!(war_polling_active: true)
    WarPollingJob.perform_later(id)
  end

  def stop_war_polling!
    update!(war_polling_active: false)
    Rails.cache.delete(war_cache_key)
  end

  def war_cache_key
    "faction:#{id}:war_data"
  end

  def whitelisted?(user)
    return false unless user
    faction_whitelists.exists?(user: user)
  end
end
