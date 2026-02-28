class FetchPersonalStatsJob < AdminApiJob
  MIN_STAT_ENHANCER = 200

  def perform(user, batch: 1, stats_date: Date.current.yesterday)
    stats = fetch_stats(user, batch, stats_date)

    check_hof_eligibility(user, stats) if batch == 1
    save_snapshot(user, stats, stats_date)

    FetchPersonalStatsJob.perform_later(user, batch: 2, stats_date: stats_date) if batch == 1
  end

  private

  def fetch_stats(user, batch, stats_date)
    stat_batch = batch == 1 ? PersonalStatSnapshot::TRACKED_STATS_BATCH_1 : PersonalStatSnapshot::TRACKED_STATS_BATCH_2

    TornApi::User::PersonalStats.new(
      AdminCredentials.api_key,
      user.torn_id,
      timestamp: stats_date.end_of_day.to_i,
      stat_batch: stat_batch
    ).fetch
  end

  def check_hof_eligibility(user, stats)
    return unless stats[:items_used_stat_enhancers].to_i > MIN_STAT_ENHANCER

    user.update!(hof_stats_user: true)
  end

  def save_snapshot(user, stats, stats_date)
    snapshot = user.personal_stat_snapshots.find_or_initialize_by(date: stats_date)
    snapshot.update!(stats.except(:date))
  end
end
