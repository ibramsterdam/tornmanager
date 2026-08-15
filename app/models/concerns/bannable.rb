module Bannable
  extend ActiveSupport::Concern

  PERMANENT = 1000.years
  PERMANENT_THRESHOLD = 100.years

  included do
    scope :banned, -> { where(banned_until: Time.current..) }
    scope :not_banned, -> { where(banned_until: nil).or(where(banned_until: ..Time.current)) }
  end

  def banned?
    banned_until.present? && banned_until.future?
  end

  def ban!(until_time = PERMANENT, reason: nil)
    until_time = until_time.from_now if until_time.is_a?(ActiveSupport::Duration)
    update!(banned_until: until_time, banned_reason: reason)
  end

  def unban!
    update!(banned_until: nil, banned_reason: nil)
  end

  def permanently_banned?
    banned? && banned_until.after?(PERMANENT_THRESHOLD.from_now)
  end

  def ban_message
    message = if permanently_banned?
      "Your access to TornManager has been suspended."
    else
      "Your access to TornManager has been suspended until #{banned_until.utc.strftime("%-d %B %Y")}."
    end
    message = "#{message} Reason: #{banned_reason}." if banned_reason.present?
    message
  end
end
