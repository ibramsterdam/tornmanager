class FetchPersonalStatsJob < ApplicationJob
  queue_as :default

  def perform(torn_user)
    stats = TornApi::User::PersonalStats.new(api_key, torn_user.torn_id).fetch
    torn_user.personal_stat_snapshots.create!(stats.to_h)
  end

  private

  def api_key
    api_key ||=Rails.application.credentials.dig(:bram, :api_key)
  end
end
