class PersonalStatSnapshot < ApplicationRecord
  belongs_to :user

  validates :date, presence: true, uniqueness: { scope: :user_id }

  before_validation :set_date, if: -> { date.nil? }

  private

  def set_date
    self.date = Date.current
  end
end
