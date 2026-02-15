module Daily
  class PersonalStatsJob < ApplicationJob
    queue_as :default

    def perform(delay = 15)
      batch_size = 60
      run_at = delay.minutes.from_now

      User.hof_stats_users.find_in_batches(batch_size:) do |users|
        users.each do |user|
          FetchPersonalStatsJob.set(wait_until: run_at).perform_later(user)
          run_at += 1.second
        end
      end
    end
  end
end
