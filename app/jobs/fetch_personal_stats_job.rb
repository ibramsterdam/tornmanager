class FetchPersonalStatsJob < FactionApiJob
  queue_with_priority 50
  limits_concurrency to: 1, key: ->(user, api_key:, **) { api_key }, group: CONCURRENCY_GROUP

  MAX_RETRIES = 3

  def perform(user, api_key:, batch: 1, stats_date: Date.current.yesterday, retries: 0)
    stats = fetch_stats(api_key, user, batch, stats_date)

    user.check_hof_eligibility!(stats[:items_used_stat_enhancers]) if batch == 1
    save_snapshot(user, stats, stats_date)

    FetchPersonalStatsJob.perform_later(user, api_key: api_key, batch: 2, stats_date: stats_date) if batch == 1
  rescue TornApi::NoDataError => e
    # Torn returned no personalstats for this user/date. This runs at 2:30am
    # TCT — well after the stats cache settles (~1am) — so a nil payload here
    # is almost always a new/inactive member or data Torn simply doesn't have,
    # not a cache-rebuild blip. Skip quietly: the nightly gap scan re-attempts
    # the date once it's older and BackfillSingleStatJob tombstones it if the
    # gap is permanent. Letting this propagate just burns 3x15min of retries
    # and pages a false alarm for something the gap scan already recovers.
    Rails.logger.info("FetchPersonalStatsJob: no data for #{user.name} (#{user.torn_id}) on #{stats_date}, batch #{batch} — leaving to nightly gap scan (#{e.message})")
  rescue TornApi::InvalidKeyError => e
    if retries < MAX_RETRIES
      Rails.logger.warn("FetchPersonalStatsJob: Failed for #{user.name} (#{user.torn_id}): #{e.message}, retry #{retries + 1}/#{MAX_RETRIES} in 1 hour")
      FetchPersonalStatsJob.set(wait: 1.hour).perform_later(user, api_key: api_key, batch: batch, stats_date: stats_date, retries: retries + 1)
    else
      Rails.logger.error("FetchPersonalStatsJob: Giving up on #{user.name} (#{user.torn_id}) after #{MAX_RETRIES} retries: #{e.message}")
      Discord::Notifier.notify(
        webhook_key: :error_webhook_url,
        embed: {
          title: "Personal Stats Fetch Failed",
          description: "Gave up after #{MAX_RETRIES} retries.\n```#{e.message}```",
          color: 15_158_332,
          fields: [
            { name: "User", value: "#{user.name} [#{user.torn_id}]", inline: true },
            { name: "Date", value: stats_date.to_s, inline: true }
          ],
          footer: { text: "TornManager Error Reporter" },
          timestamp: Time.current.iso8601
        }
      )
    end
  end

  private

  def fetch_stats(api_key, user, batch, stats_date)
    stat_batch = batch == 1 ? PersonalStatSnapshot::TRACKED_STATS_BATCH_1 : PersonalStatSnapshot::TRACKED_STATS_BATCH_2

    TornApi::User::PersonalStats.new(
      api_key,
      user.torn_id,
      timestamp: stats_date.end_of_day.to_i,
      stat_batch: stat_batch
    ).fetch
  end

  def save_snapshot(user, stats, stats_date)
    snapshot = user.personal_stat_snapshots.find_or_initialize_by(date: stats_date)
    snapshot.update!(stats.except(:date))
  end
end
