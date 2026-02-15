class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :personal_stat_snapshots, dependent: :destroy
  has_many :received_xanax_payments, class_name: "XanaxPayment", foreign_key: :recipient_id, dependent: :destroy
  has_many :sent_xanax_payments, class_name: "XanaxPayment", foreign_key: :sender_id
  has_many :subscription_grants, dependent: :destroy
  has_many :faction_subscription_grants, through: :subscription_grants
  has_many :granted_faction_subscriptions, class_name: "FactionSubscriptionGrant", foreign_key: :granted_by_id

  validates :api_key, uniqueness: true, allow_nil: true
  validates :torn_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :level, presence: true

  scope :hof_stats_users, -> { where(hof_stats_user: true) }
  scope :active_subscribers, -> { where("subscription_expires_at > ?", Time.current) }

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
end
