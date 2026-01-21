module Daily
  class PersonalStatsJob < ApplicationJob
    queue_as :default

    def perform(*args)
      batch_size = 60
      delay_time = 1.second

      TornUser.find_in_batches(batch_size:) do |users|
        users.each do |torn_user|
          FetchPersonalStatsJob.set(wait_until: delay_time.from_now).perform_later(torn_user)
          delay_time += 1.second
        end
      end
    end
  end
end
