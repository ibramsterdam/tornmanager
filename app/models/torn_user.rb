class TornUser < ApplicationRecord
  has_one :user
  has_many :personal_stat_snapshots, dependent: :destroy
  scope :hof_stats_users, -> { where(hof_stats_user: true) }
end
