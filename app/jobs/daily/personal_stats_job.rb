module Daily
  class PersonalStatsJob < ApplicationJob
    queue_as :default

    def perform(delay = 15)
      batch_size = 60
      run_at = delay.minutes.from_now
      total_users = 0

      User.tracked_for_stats.find_in_batches(batch_size:) do |users|
        users.each do |user|
          FetchPersonalStatsJob.set(wait_until: run_at).perform_later(user)
          run_at += 1.second
          total_users += 1
        end
      end

      ::Appsignal.set_gauge("jobs.personal_stats_scheduled", total_users) if defined?(::Appsignal)
    end
  end
end
