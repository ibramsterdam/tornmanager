class BackfillSingleStatJob < FactionApiJob
  queue_with_priority 100
  limits_concurrency to: 1, key: ->(user_id, date_str, faction_id:, api_key: nil, **) { api_key }, group: CONCURRENCY_GROUP

  def perform(user_id, date_str, faction_id:, batch: 1, api_key: nil)
    user = User.find(user_id)
    date = Date.parse(date_str)

    return Rails.logger.error("BackfillSingleStatJob: No API key for #{user.name}, skipping") if api_key.blank?

    stats = fetch_stats(user, date, api_key, batch)
    return if stats.nil?

    save_snapshot(user, stats, date)

    BackfillSingleStatJob.perform_later(user_id, date_str, faction_id: faction_id, batch: 2, api_key: api_key) if batch == 1
  rescue TornApi::NoDataError
    # Torn has nothing for this player/date — tombstone the date so the
    # nightly gap scan stops re-fetching it forever.
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
    # Unrecoverable for this user/key — skip the date. Rate limits and
    # transient errors propagate so retry_on reschedules instead of the
    # gap silently re-enqueueing every night.
    Rails.logger.error("API error fetching stats: #{e.message}")
    nil
  end

  def save_snapshot(user, stats, date)
    snapshot = user.personal_stat_snapshots.find_or_initialize_by(date: date)
    snapshot.update!(stats.except(:date))
  end
end
