class BackfillPersonalStatsJob < ApplicationJob
  queue_as :default

  def perform(faction_id, start_date, end_date)
    faction = Faction.find(faction_id)
    users = faction.users.to_a
    dates = (start_date.to_date..end_date.to_date).to_a

    Rails.logger.info("Scheduling backfill for faction #{faction.name}: #{users.count} users, #{dates.size} days")

    delay = 0.seconds
    jobs_scheduled = 0

    # Schedule all jobs with sequential delays to avoid rate limiting
    users.each do |user|
      # Get existing snapshots for this user
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
    end

    total_seconds = [ delay.to_i, 1 ].max

    faction.update!(
      backfill_ends_at: Time.current + total_seconds.seconds,
      backfill_target_date: start_date.to_date
    )

    # Schedule cleanup job to clear backfill status when done
    ClearBackfillStatusJob.set(wait: total_seconds.seconds).perform_later(faction.id)

    Rails.logger.info("Scheduled #{jobs_scheduled} stat fetch jobs for faction #{faction.name}, completing in ~#{total_seconds}s")
  end
end
