class FactionSetting < ApplicationRecord
  belongs_to :faction

  validates :faction_id, uniqueness: true
end
