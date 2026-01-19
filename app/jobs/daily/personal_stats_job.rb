module Daily
  class PersonalStatsJob < ApplicationJob
    queue_as :default

    def perform(*args)
      batch_size = 50
      delay_between_batches = 1.minute

      TornUser.find_in_batches(batch_size: batch_size).with_index do |users, batch_index|
        run_time = Time.current + batch_index * delay_between_batches

        users.each do |torn_user|
          FetchPersonalStatsJob.set(wait_until: run_time).perform_later(torn_user)
        end
      end
    end
  end
end
