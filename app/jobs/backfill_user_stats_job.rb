class BackfillUserStatsJob < ApplicationJob
  queue_as :default

  # Used for backfilling a single user (not called by BackfillPersonalStatsJob anymore)
  def perform(user_id, start_date, end_date)
    user = User.find(user_id)
    dates = (start_date.to_date..end_date.to_date).to_a

    Rails.logger.info("Scheduling backfill for user #{user.name} (#{user.torn_id}): #{dates.size} days")

    jobs_scheduled = 0

    # Get existing snapshots by date
    existing_dates = user.personal_stat_snapshots
                         .where(date: dates.first..dates.last)
                         .pluck(:date)
                         .to_set

    dates.each do |date|
      # Skip if we already have a snapshot for this date
      next if existing_dates.include?(date)

      # Jobs go to owner_api queue which handles rate limiting (~1 req/sec)
      BackfillSingleStatJob.perform_later(user.id, date.to_s)
      jobs_scheduled += 1
    end

    Rails.logger.info("Scheduled #{jobs_scheduled} stat fetch jobs for user #{user.name}")
  end
end
