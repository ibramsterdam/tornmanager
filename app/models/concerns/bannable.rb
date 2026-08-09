module Bannable
  extend ActiveSupport::Concern

  # A ban with no duration effectively never expires.
  PERMANENT = 1000.years

  included do
    scope :banned, -> { where(banned_until: Time.current..) }
    scope :not_banned, -> { where(banned_until: nil).or(where(banned_until: ..Time.current)) }
  end

  def banned?
    banned_until.present? && banned_until.future?
  end

  # user.ban!            -> permanent
  # user.ban!(24.hours)  -> temporary, auto-lifts when it expires
  def ban!(duration = PERMANENT)
    update!(banned_until: duration.from_now)
  end

  def unban!
    update!(banned_until: nil)
  end
end
