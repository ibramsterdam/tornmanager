class User < ApplicationRecord
  belongs_to :faction, optional: true
  has_many :sessions, dependent: :destroy
  has_many :personal_stat_snapshots, dependent: :destroy
  has_many :received_xanax_payments, class_name: "XanaxPayment", foreign_key: :recipient_id, dependent: :destroy
  has_many :sent_xanax_payments, class_name: "XanaxPayment", foreign_key: :sender_id
  has_many :subscription_grants, dependent: :destroy
  has_many :faction_subscription_grants, through: :subscription_grants
  has_many :granted_faction_subscriptions, class_name: "FactionSubscriptionGrant", foreign_key: :granted_by_id
  has_many :api_calls, dependent: :destroy
  has_many :faction_whitelists, dependent: :destroy

  validates :api_key, uniqueness: true, allow_nil: true
  validates :torn_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :level, presence: true

  scope :hof_stats_users, -> { where(hof_stats_user: true) }
  scope :active_subscribers, -> { where("subscription_expires_at > ?", Time.current) }
  scope :active, -> { where(fallen: false) }
  scope :fallen, -> { where(fallen: true) }
  scope :tracked_for_stats, -> {
    left_joins(:faction)
      .where(fallen: false)
      .where("hof_stats_user = ? OR factions.track_stats = ?", true, true)
      .distinct
  }

  LIMITED_ACCESS_TYPES = [ "Limited Access", "Full Access", "Custom" ].freeze

  def subscribed?
    subscription_expires_at.present? && subscription_expires_at > Time.current
  end

  def extend_subscription!(weeks)
    new_expiry = subscribed? ? subscription_expires_at + weeks.weeks : Time.current + weeks.weeks
    update!(subscription_expires_at: new_expiry)
  end

  def admin?
    torn_id == 2728237
  end

  def has_limited_access?
    LIMITED_ACCESS_TYPES.include?(api_access_type)
  end

  def backfill_in_progress?
    backfill_ends_at.present? && backfill_ends_at > Time.current
  end

  def backfill_seconds_remaining
    return 0 unless backfill_in_progress?
    (backfill_ends_at - Time.current).to_i
  end
end
