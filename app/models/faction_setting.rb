class FactionSetting < ApplicationRecord
  belongs_to :faction

  validates :faction_id, uniqueness: true
  validates :payout_faction_cut, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :payout_assist_value, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
end
