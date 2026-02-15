class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :personal_stat_snapshots, dependent: :destroy

  validates :api_key, uniqueness: true, allow_nil: true
  validates :torn_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :level, presence: true

  scope :hof_stats_users, -> { where(hof_stats_user: true) }
end
