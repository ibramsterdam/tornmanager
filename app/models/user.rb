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
  has_many :chat_memberships, dependent: :delete_all
  has_many :chat_rooms, through: :chat_memberships
  has_many :hosted_chat_rooms, class_name: "ChatRoom", foreign_key: :host_user_id, dependent: :destroy
  has_one :torn_api_key, class_name: "ApiKey::Torn", foreign_key: :user_id, dependent: :destroy
  has_one :subscription, as: :subscribable, dependent: :destroy

  validates :torn_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :level, presence: true

  scope :hof_stats_users, -> { where(hof_stats_user: true) }
  scope :active_subscribers, -> {
    left_joins(:subscription).where("subscriptions.expires_at > ?", Time.current)
  }
  scope :active, -> { where(fallen: false) }
  scope :fallen, -> { where(fallen: true) }
  scope :tracked_for_stats, -> {
    base = left_joins(faction: :api_keys).where(fallen: false)
    base.where(hof_stats_user: true)
      .or(base.where(factions: { setup_completed: true }, api_keys: { type: "ApiKey::Torn" }))
      .distinct
  }

  LIMITED_ACCESS_TYPES = [ "Limited Access", "Full Access", "Custom" ].freeze

  def self.find_by_api_key(key)
    joins(:torn_api_key).find_by(api_keys: { key: key })
  end

  def subscribed?
    (subscription&.expires_at.present? && subscription.expires_at > Time.current) ||
      (faction&.subscription&.expires_at.present? && faction.subscription.expires_at > Time.current)
  end

  def personal_subscription_active?
    subscription&.expires_at.present? && subscription.expires_at > Time.current
  end

  def subscription_weeks_remaining
    return 0 unless personal_subscription_active?
    ((subscription.expires_at - Time.current) / 1.week).round
  end

  def effective_subscription_expires_at
    candidates = []
    candidates << subscription.expires_at if subscription&.expires_at.present?
    candidates << faction.subscription.expires_at if faction&.subscription&.expires_at.present?
    candidates.compact.max
  end

  def extend_subscription!(weeks)
    if subscription
      subscription.extend!(weeks)
    else
      create_subscription!(expires_at: Time.current + weeks.weeks)
    end
  end

  def deduct_subscription!(weeks)
    raise "Not enough subscription time remaining" unless subscription_weeks_remaining >= weeks
    subscription.update!(expires_at: subscription.expires_at - weeks.weeks)
  end

  ADMIN_TORN_ID = 2728237

  def admin?
    torn_id == ADMIN_TORN_ID
  end

  def hof_access?
    admin? || torn_id == 2685512
  end

  HOF_STAT_ENHANCER_THRESHOLD = 200

  def check_hof_eligibility!(stat_enhancer_count)
    update!(hof_stats_user: true) if stat_enhancer_count.to_i > HOF_STAT_ENHANCER_THRESHOLD
  end

  def faction_leader?
    %w[Leader Co-leader].include?(position)
  end

  def has_limited_access?
    LIMITED_ACCESS_TYPES.include?(api_access_type)
  end

  def api_key
    torn_api_key&.key
  end

  def api_access_type
    torn_api_key&.access_type
  end

  def set_api_key!(key, access_type)
    if key.nil?
      torn_api_key&.destroy!
      self.torn_api_key = nil
    elsif torn_api_key
      torn_api_key.update!(key: key, access_type: access_type)
    else
      create_torn_api_key!(key: key, access_type: access_type)
    end
  end

  def backfill_in_progress?
    backfill_ends_at.present? && backfill_ends_at > Time.current
  end

  def backfill_seconds_remaining
    return 0 unless backfill_in_progress?
    (backfill_ends_at - Time.current).to_i
  end
end
