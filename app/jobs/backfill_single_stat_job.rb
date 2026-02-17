class BackfillSingleStatJob < ApplicationJob
  queue_as :default

  def perform(user_id, date_str)
    user = User.find(user_id)
    date = Date.parse(date_str)
    api_key = OwnerCredentials.api_key

    return Rails.logger.error("No API key found") if api_key.blank?

    request_timestamp = date.to_time.to_i

    stats = fetch_stats(user.torn_id, request_timestamp, api_key)

    return if stats.nil?

    # Use the timestamp returned by the API
    response_timestamp = stats.timestamp
    response_date = Time.at(response_timestamp).utc.to_date
    stats_data = stats.to_h.except(:timestamp)

    # Find existing snapshot for this day, or initialize new one with response timestamp
    day_start = response_date.beginning_of_day.to_i
    day_end = response_date.end_of_day.to_i
    snapshot = user.personal_stat_snapshots.find_by(timestamp: day_start..day_end)
    snapshot ||= user.personal_stat_snapshots.new(timestamp: response_timestamp)

    snapshot.assign_attributes(stats_data)

    if snapshot.save
      Rails.logger.debug("Upserted snapshot for user #{user.torn_id} on #{snapshot.date}")
    else
      Rails.logger.error("Failed to save snapshot for user #{user.torn_id} on #{snapshot.date}: #{snapshot.errors.full_messages.join(', ')}")
    end
  end

  private

  def fetch_stats(torn_id, timestamp, api_key)
    api = TornApi::User::PersonalStats.new(api_key, torn_id, timestamp: timestamp)
    api.fetch
  rescue TornApi::ApiError => e
    Rails.logger.error("API error fetching stats: #{e.message}")
    nil
  end
end
