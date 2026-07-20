class BackfillSingleStatJob < FactionApiJob
  queue_with_priority 100
  limits_concurrency to: 1, key: ->(user_id, date_str, faction_id:, api_key: nil, **) { api_key }, group: CONCURRENCY_GROUP

  # Backfill is the lowest-priority work on a contended key. A faction signup
  # fans thousands of these onto one key at once (Jan 1 → yesterday per member),
  # right when the leader is actively browsing their new dashboard — so the key
  # budget is regularly spent and these trip the client-side rate limiter. That
  # is expected back-pressure, not a failure: background work must yield to live
  # traffic. So retry patiently and with jitter (a re-enqueue releases the worker
  # and the per-key concurrency lock means retries never pile up, so attempts are
  # cheap) — this lets a signup backfill drain itself once traffic quiets instead
  # of dribbling in at the gap scan's 30/user/night cap. If even that patience is
  # exhausted, drop quietly with a log line; the nightly gap scan is the backstop.
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
