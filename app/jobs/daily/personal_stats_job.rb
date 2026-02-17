module Daily
  class PersonalStatsJob < ApplicationJob
    queue_as :default

    def perform
      total_users = 0

      User.tracked_for_stats.find_each do |user|
        # Jobs go to torn_api queue which handles rate limiting (~1 req/sec)
        FetchPersonalStatsJob.perform_later(user)
        total_users += 1
      end

      ::Appsignal.set_gauge("jobs.personal_stats_scheduled", total_users) if defined?(::Appsignal)
    end
  end
end
