class BackfillSingleStatJob < FactionApiJob
  queue_with_priority 100
  limits_concurrency to: 1, key: ->(user_id, date_str, faction_id:, api_key: nil, **) { api_key }, group: CONCURRENCY_GROUP

  # A faction signup fans thousands of these onto one key at once, so rate-limit
  # rejections here are expected back-pressure, not failures: retry patiently,
  # and if retries run out, drop quietly — the nightly gap scan is the backstop.
  retry_on TornApi::RateLimitError, wait: 2.minutes, attempts: 15, jitter: 0.5 do |job, error|
    user_id, date_str = job.arguments
    Rails.logger.warn("BackfillSingleStatJob: gave up on user #{user_id} #{date_str} after rate-limit retries — nightly gap scan will retry (#{error.message})")
  end

  def perform(user_id, date_str, faction_id:, batch: 1, api_key: nil)
    user = User.find(user_id)
    date = Date.parse(date_str)

    return Rails.logger.error("BackfillSingleStatJob: No API key for #{user.name}, skipping") if api_key.blank?

    stats = fetch_stats(user, date, api_key, batch)
    return if stats.nil?

    save_snapshot(user, stats, date)

    BackfillSingleStatJob.perform_later(user_id, date_str, faction_id: faction_id, batch: 2, api_key: api_key) if batch == 1
  rescue TornApi::NoDataError
    # Tombstone the date so the nightly gap scan stops re-fetching it.
    tombstone = user.personal_stat_snapshots.find_or_initialize_by(date: date)
    tombstone.update!(torn_data_missing: true)
    Rails.logger.info("BackfillSingleStatJob: tombstoned #{user.name} #{date} — no data at Torn")
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
  rescue TornApi::NotFoundError, TornApi::InvalidKeyError => e
    # Unrecoverable for this user/key — skip the date; retryable errors propagate to retry_on.
    Rails.logger.error("API error fetching stats: #{e.message}")
    nil
  end

  def save_snapshot(user, stats, date)
    snapshot = user.personal_stat_snapshots.find_or_initialize_by(date: date)
    snapshot.update!(stats.except(:date))
  end
end
