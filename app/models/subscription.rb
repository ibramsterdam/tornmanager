class Subscription < ApplicationRecord
  belongs_to :subscribable, polymorphic: true

  validates :expires_at, presence: true
  validates :subscribable_type, uniqueness: { scope: :subscribable_id }

  def active?
    expires_at.present? && expires_at > Time.current
  end

  def days_remaining
    return 0 unless active?
    ((expires_at - Time.current) / 1.day).ceil
  end

  def extend!(weeks)
    new_expiry = active? ? expires_at + weeks.weeks : Time.current + weeks.weeks
    update!(expires_at: new_expiry)
  end
end
