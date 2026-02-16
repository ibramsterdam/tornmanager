class PersonalStatSnapshot < ApplicationRecord
  belongs_to :user

  validates :date, presence: true, uniqueness: { scope: :user_id }

  before_validation :set_date_from_created_at, if: -> { date.nil? && created_at.present? }

  private

  def set_date_from_created_at
    self.date = created_at.to_date
  end
end
