class TornUser < ApplicationRecord
  has_one :user
  has_many :personal_stat_snapshots, dependent: :destroy
end
