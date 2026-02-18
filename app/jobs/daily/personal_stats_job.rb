module Daily
  class PersonalStatsJob < ApplicationJob
    queue_as :default

    def perform
      User.tracked_for_stats.find_each do |user|
        FetchPersonalStatsJob.perform_later(user)
      end
    end
  end
end
