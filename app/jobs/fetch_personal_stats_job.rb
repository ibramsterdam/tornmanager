class FetchPersonalStatsJob < FactionApiJob
  limits_concurrency to: 1, key: ->(user, api_key:, **) { api_key }, group: "PersonalStatsApiCalls"

  MAX_RETRIES = 3

  def perform(user, api_key:, batch: 1, stats_date: Date.current.yesterday, retries: 0)
    stats = fetch_stats(api_key, user, batch, stats_date)

    user.check_hof_eligibility!(stats[:items_used_stat_enhancers]) if batch == 1
    save_snapshot(user, stats, stats_date)

    FetchPersonalStatsJob.perform_later(user, api_key: api_key, batch: 2, stats_date: stats_date) if batch == 1
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
