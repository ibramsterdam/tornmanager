module Daily
  class PersonalStatsJob < ApplicationJob
    queue_as :default

    # Each stats fetch requires 2 API calls (batch 1 + batch 2), spaced 1 second apart
    # So we schedule each user 2 seconds apart to avoid rate limiting
    SECONDS_PER_FETCH = 2

    def perform(delay = 15)
      batch_size = 60
      run_at = delay.minutes.from_now
      total_users = 0

      User.tracked_for_stats.find_in_batches(batch_size:) do |users|
        users.each do |user|
          FetchPersonalStatsJob.set(wait_until: run_at).perform_later(user)
          run_at += SECONDS_PER_FETCH.seconds
          total_users += 1
        end
      end

      ::Appsignal.set_gauge("jobs.personal_stats_scheduled", total_users) if defined?(::Appsignal)
    end
  end
end
