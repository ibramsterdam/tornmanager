module Daily
  class PersonalStatsJob < ApplicationJob
    queue_as :default

    def perform(*args)
      batch_size = 60

      TornUser.find_in_batches(batch_size: batch_size).with_index do |users, i|
        users.each do |torn_user|
          FetchPersonalStatsJob.set(wait_until: i.minutes).perform_later(torn_user)
        end
      end
    end
  end
end
