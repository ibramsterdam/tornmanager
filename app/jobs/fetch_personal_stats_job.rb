class FetchPersonalStatsJob < TornApiJob
  MIN_STAT_ENHANCER = 200

  # @param user [User] User to fetch stats for
  # @param batch [Integer] Which batch to fetch (1 or 2), defaults to 1 which schedules batch 2
  # @param target_date [Date, nil] The date to save stats for (batch 2 uses this to find batch 1's snapshot)
  def perform(user, batch: 1, target_date: nil)
    stat_batch = batch == 1 ? PersonalStatSnapshot::TRACKED_STATS_BATCH_1 : PersonalStatSnapshot::TRACKED_STATS_BATCH_2

    stats = TornApi::User::PersonalStats.new(OwnerCredentials.api_key, user.torn_id, stat_batch: stat_batch).fetch

    # Check HoF eligibility only on batch 1 (which has stat_enhancers)
    if batch == 1 && stats[:items_used_stat_enhancers].to_i > MIN_STAT_ENHANCER
      user.update!(hof_stats_user: true)
    end

    # Determine the date for this snapshot
    # - Batch 1: use the API response timestamp
    # - Batch 2: use the target_date passed from batch 1 (API may return different timestamp)
    response_timestamp = stats[:timestamp]
    snapshot_date = target_date || Time.at(response_timestamp).utc.to_date
    day_start = snapshot_date.beginning_of_day.to_i
    day_end = snapshot_date.end_of_day.to_i

    snapshot = user.personal_stat_snapshots.find_by(timestamp: day_start..day_end)
    snapshot ||= user.personal_stat_snapshots.new(timestamp: response_timestamp)
    snapshot.assign_attributes(stats.except(:timestamp))
    snapshot.save!

    # Enqueue batch 2 if this was batch 1 (queue handles rate limiting)
    if batch == 1
      FetchPersonalStatsJob.perform_later(user, batch: 2, target_date: snapshot_date)
    end

    ::Appsignal.increment_counter("jobs.personal_stats_fetched", 1) if defined?(::Appsignal)
  rescue => e
    ::Appsignal.increment_counter("jobs.personal_stats_failed", 1) if defined?(::Appsignal)
    raise
  end
end
