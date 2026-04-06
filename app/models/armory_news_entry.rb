class ArmoryNewsEntry < ApplicationRecord
  belongs_to :faction

  validates :torn_news_id, presence: true, uniqueness: { scope: :faction_id }
  validates :action, :occurred_at, presence: true

  scope :recent, ->(duration = 1.year) { where(occurred_at: duration.ago..) }
  scope :loans_and_returns, -> { where(action: %w[loaned returned]) }
  scope :by_member, ->(player_id) { where(player_id: player_id) }
  scope :newest_first, -> { order(occurred_at: :desc) }
end
