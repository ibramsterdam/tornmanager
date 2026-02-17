class BackfillUserStatsJob < ApplicationJob
  queue_as :default

  # Used for backfilling a single user (not called by BackfillPersonalStatsJob anymore)
  def perform(user_id, start_date, end_date)
    user = User.find(user_id)
    dates = (start_date.to_date..end_date.to_date).to_a

    Rails.logger.info("Scheduling backfill for user #{user.name} (#{user.torn_id}): #{dates.size} days")

    delay = 0.seconds
    jobs_scheduled = 0

    # Get existing snapshots and index by date (derived from timestamp)
    existing_snapshots = user.personal_stat_snapshots
                            .where(timestamp: dates.first.to_time.to_i..dates.last.end_of_day.to_i)
                            .pluck(:timestamp)
                            .map { |ts| Time.at(ts).utc.to_date }
                            .to_set

    dates.each do |date|
      # Skip if we already have a snapshot for this date
      next if existing_snapshots.include?(date)

      BackfillSingleStatJob.set(wait: delay).perform_later(user.id, date.to_s)
      delay += 1.second
      jobs_scheduled += 1
    end

    Rails.logger.info("Scheduled #{jobs_scheduled} stat fetch jobs for user #{user.name}")
  end
end
