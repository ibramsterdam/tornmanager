class FetchPersonalStatsJob < ApplicationJob
  queue_as :default

  MIN_STAT_ENHANCER = 200

  def perform(user)
    stats = TornApi::User::PersonalStats.new(OwnerCredentials.api_key, user.torn_id).fetch
    user.update!(hof_stats_user: true) if stats.items_used_stat_enhancers.to_i > MIN_STAT_ENHANCER

    # Find existing snapshot for this day, or create new one
    response_timestamp = stats.timestamp
    response_date = Time.at(response_timestamp).utc.to_date
    day_start = response_date.beginning_of_day.to_i
    day_end = response_date.end_of_day.to_i

    snapshot = user.personal_stat_snapshots.find_by(timestamp: day_start..day_end)
    snapshot ||= user.personal_stat_snapshots.new(timestamp: response_timestamp)
    snapshot.assign_attributes(stats.to_h.except(:timestamp))
    snapshot.save!

    ::Appsignal.increment_counter("jobs.personal_stats_fetched", 1) if defined?(::Appsignal)
  rescue => e
    ::Appsignal.increment_counter("jobs.personal_stats_failed", 1) if defined?(::Appsignal)
    raise
  end
end
