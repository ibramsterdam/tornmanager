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
    calls = case scope
    when :today
              user.api_calls.today.order(:created_at)
    else
              user.api_calls.order(:created_at)
    end

    return { rate: 0, minute_start: nil } if calls.empty?

    max_rate = 0
    max_minute = nil

    calls.each do |call|
      minute_start = call.created_at.beginning_of_minute
      minute_end = minute_start + 1.minute

      scope_calls = case scope
      when :today
                      user.api_calls.today
      else
                      user.api_calls
      end

      rate = scope_calls.where(created_at: minute_start..minute_end).count

      if rate > max_rate
        max_rate = rate
        max_minute = minute_start
      end
    end

    { rate: max_rate, minute_start: max_minute }
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
