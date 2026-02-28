class ApiCall < ApplicationRecord
  MINUTE_BUCKET = Arel.sql("strftime('%Y-%m-%d %H:%M', created_at)")

  belongs_to :user
  belongs_to :faction, optional: true

  validates :endpoint, presence: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }
  scope :last_24_hours, -> { where("created_at >= ?", 24.hours.ago) }
  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "error") }

  after_create :broadcast_api_call

  def self.peak_rate_for(user, scope: :all)
    calls = scope == :today ? user.api_calls.today : user.api_calls

    minute, count = calls
      .group(MINUTE_BUCKET)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(1)
      .pick(MINUTE_BUCKET, Arel.sql("COUNT(*)"))

    { rate: count || 0, minute_start: minute ? Time.zone.parse(minute) : nil }
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
