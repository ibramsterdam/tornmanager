class FactionSubscriptionGrant < ApplicationRecord
  belongs_to :granted_by, class_name: "User"
  has_many :subscription_grants, dependent: :destroy
  has_many :users, through: :subscription_grants

  validates :faction_id, presence: true
  validates :faction_name, presence: true
  validates :weeks_granted, presence: true, numericality: { greater_than: 0 }
  validates :granted_at, presence: true

  scope :recent, -> { order(granted_at: :desc) }
end
