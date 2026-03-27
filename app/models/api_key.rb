class ApiKey < ApplicationRecord
  belongs_to :faction

  validates :key, presence: true
  validates :type, presence: true
  validates :type, uniqueness: { scope: :faction_id }
end
