class FetchPersonalStatsJob < ApplicationJob
  queue_as :default

  MIN_STAT_ENHANCER = 200

  def perform(torn_user)
    stats = TornApi::User::PersonalStats.new(api_key, torn_user.torn_id).fetch
    torn_user.update!(hof_stats_user: true) if stats.items_used_stat_enhancers > MIN_STAT_ENHANCER
    torn_user.personal_stat_snapshots.create!(stats.to_h)
  end

  private

  def api_key
    Rails.application.credentials.dig(:bram, :api_key)
  end
end
