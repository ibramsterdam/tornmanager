class FactionWhitelist < ApplicationRecord
  belongs_to :faction
  belongs_to :user

  validates :user_id, uniqueness: { scope: :faction_id }
end
