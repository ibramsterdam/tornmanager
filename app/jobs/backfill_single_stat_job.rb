class BackfillSingleStatJob < TornApiJob
  def perform(user_id, date_str, batch: 1)
    user = User.find(user_id)
    date = Date.parse(date_str)
    api_key = OwnerCredentials.api_key

    return Rails.logger.error("No API key found") if api_key.blank?

    stats = fetch_stats(user, date, api_key, batch)
    return if stats.nil?

    save_snapshot(user, stats, date)

    BackfillSingleStatJob.perform_later(user_id, date_str, batch: 2) if batch == 1
  end

  private

  def fetch_stats(user, date, api_key, batch)
    stat_batch = batch == 1 ? PersonalStatSnapshot::TRACKED_STATS_BATCH_1 : PersonalStatSnapshot::TRACKED_STATS_BATCH_2

    TornApi::User::PersonalStats.new(
      api_key,
      user.torn_id,
      timestamp: date.end_of_day.to_i,
      stat_batch: stat_batch
    ).fetch
  rescue TornApi::ApiError => e
    Rails.logger.error("API error fetching stats: #{e.message}")
    nil
  end

  def save_snapshot(user, stats, date)
    snapshot = user.personal_stat_snapshots.find_or_initialize_by(date: date)
    snapshot.update!(stats.except(:date))
  end
end
