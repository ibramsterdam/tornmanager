class FetchPersonalStatsJob < ApplicationJob
  queue_as :default

  MIN_STAT_ENHANCER = 200

  def perform(user)
    stats = TornApi::User::PersonalStats.new(OwnerCredentials.api_key, user.torn_id).fetch
    user.update!(hof_stats_user: true) if stats.items_used_stat_enhancers > MIN_STAT_ENHANCER
    user.personal_stat_snapshots.create!(stats.to_h)

    Appsignal.increment_counter("jobs.personal_stats_fetched", 1)
  rescue => e
    Appsignal.increment_counter("jobs.personal_stats_failed", 1)
    raise
  end
end
