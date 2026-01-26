module Daily
  class PersonalStatsJob < ApplicationJob
    queue_as :default

    def perform(delay = 15)
      batch_size = 60
      run_at = delay.minutes.from_now

      TornUser.hof_stats_users.find_in_batches(batch_size:) do |users|
        users.each do |torn_user|
          FetchPersonalStatsJob.set(wait_until: run_at).perform_later(torn_user)
          run_at += 1.second
        end
      end
    end
  end
end
