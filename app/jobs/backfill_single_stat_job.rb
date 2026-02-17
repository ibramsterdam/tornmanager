class BackfillSingleStatJob < ApplicationJob
  queue_as :default

  # @param user_id [Integer] User ID
  # @param date_str [String] Date string (YYYY-MM-DD)
  # @param batch [Integer] Which batch to fetch (1 or 2), defaults to 1 which schedules batch 2
  def perform(user_id, date_str, batch: 1)
    user = User.find(user_id)
    date = Date.parse(date_str)
    api_key = OwnerCredentials.api_key

    return Rails.logger.error("No API key found") if api_key.blank?

    request_timestamp = date.to_time.to_i
    stat_batch = batch == 1 ? PersonalStatSnapshot::TRACKED_STATS_BATCH_1 : PersonalStatSnapshot::TRACKED_STATS_BATCH_2

    stats = fetch_stats(user.torn_id, request_timestamp, api_key, stat_batch)

    return if stats.nil?

    # Use the original request date for snapshot lookup, not API response timestamp
    # (API may return different timestamps between batch 1 and batch 2)
    response_timestamp = stats[:timestamp]
    stats_data = stats.except(:timestamp)

    # Find existing snapshot for the target date, or initialize new one
    day_start = date.beginning_of_day.to_i
    day_end = date.end_of_day.to_i
    snapshot = user.personal_stat_snapshots.find_by(timestamp: day_start..day_end)
    snapshot ||= user.personal_stat_snapshots.new(timestamp: response_timestamp)

    snapshot.assign_attributes(stats_data)

    if snapshot.save
      Rails.logger.debug("Upserted snapshot for user #{user.torn_id} on #{snapshot.date} (batch #{batch})")
    else
      Rails.logger.error("Failed to save snapshot for user #{user.torn_id} on #{snapshot.date}: #{snapshot.errors.full_messages.join(', ')}")
    end

    # Schedule batch 2 if this was batch 1
    if batch == 1
      BackfillSingleStatJob.set(wait: 1.second).perform_later(user_id, date_str, batch: 2)
    end
  end

  private

  def fetch_stats(torn_id, timestamp, api_key, stat_batch)
    api = TornApi::User::PersonalStats.new(api_key, torn_id, timestamp: timestamp, stat_batch: stat_batch)
    api.fetch
  rescue TornApi::ApiError => e
    Rails.logger.error("API error fetching stats: #{e.message}")
    nil
  end
end
