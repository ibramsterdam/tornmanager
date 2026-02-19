class ApiCall < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }
  scope :last_24_hours, -> { where("created_at >= ?", 24.hours.ago) }
  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "error") }

  after_create :broadcast_api_call

  def self.peak_rate_for(user, scope: :all)
    base = case scope
    when :today
              user.api_calls.today
    else
              user.api_calls
    end

    result = base
      .group(Arel.sql("strftime('%Y-%m-%d %H:%M', created_at)"))
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(1)
      .pluck(Arel.sql("strftime('%Y-%m-%d %H:%M', created_at), COUNT(*)"))
      .first

    if result
      { rate: result[1], minute_start: Time.zone.parse(result[0]) }
    else
      { rate: 0, minute_start: nil }
    end
  end

  private

  def broadcast_api_call
    ApiRateMonitorChannel.broadcast_to(user, {
      id: id,
      endpoint: endpoint,
      status: status,
      response_time: response_time,
      created_at: created_at.iso8601
    })
  end
end
