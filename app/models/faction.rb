class Faction < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :faction_subscription_grants, dependent: :nullify

  validates :torn_id, presence: true, uniqueness: true
  validates :name, presence: true

  scope :tracked, -> { where(track_stats: true) }

  def member_count
    users.count
  end
end
