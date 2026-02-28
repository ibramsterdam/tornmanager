class Factions::Leadership::ApiLogsController < Factions::Leadership::BaseController
  def show
    load_api_logs_data
  end

  private

  def load_api_logs_data
    base_scope = @faction.api_calls

    @api_logs = base_scope.recent.limit(500)

    @total_calls = base_scope.count
    @successful_calls = base_scope.successful.count
    @failed_calls = base_scope.failed.count
    @avg_response_time = base_scope.where.not(response_time: nil).average(:response_time)&.round(0)

    @calls_today = base_scope.today.count
    @calls_last_24h = base_scope.last_24_hours.count

    @peak_rate_today = calculate_api_peak_rate(base_scope.today)
  end

  def calculate_api_peak_rate(scope)
    counts_by_minute = scope
      .group("strftime('%Y-%m-%d %H:%M', created_at)")
      .count

    return { rate: 0, minute_start: nil } if counts_by_minute.empty?

    max_minute, max_rate = counts_by_minute.max_by { |_, count| count }
    { rate: max_rate, minute_start: max_minute }
  end
end
