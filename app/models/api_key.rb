class ApiKey < ApplicationRecord
  belongs_to :faction, optional: true
  belongs_to :user, optional: true

  validates :key, presence: true
  validates :type, presence: true
  validates :type, uniqueness: { scope: :faction_id }, if: -> { faction_id.present? }
  validates :type, uniqueness: { scope: :user_id }, if: -> { user_id.present? }
  validate :faction_or_user_present

  private

  def faction_or_user_present
    if faction_id.blank? && user_id.blank?
      errors.add(:base, "must belong to either a faction or a user")
    end
  end
end
