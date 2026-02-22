class BackfillPersonalStatsJob < ApplicationJob
  queue_as :default

  # Seconds per API call (polling_interval of owner_api queue)
  SECONDS_PER_API_CALL = 1.1

  def perform(faction_id, start_date, end_date)
    faction = Faction.find(faction_id)
    users = faction.users.active.to_a
    dates = (start_date.to_date..end_date.to_date).to_a

    Rails.logger.info("Scheduling backfill for faction #{faction.name}: #{users.count} users, #{dates.size} days")

    jobs_scheduled = 0

    # Enqueue all jobs - owner_api queue handles rate limiting (~1 req/sec)
    users.each do |user|
      # Get existing snapshots for this user
      existing_dates = user.personal_stat_snapshots
                           .where(date: dates.first..dates.last)
                           .pluck(:date)
                           .to_set

      dates.each do |date|
        # Skip if we already have a snapshot for this date
        next if existing_dates.include?(date)

        BackfillSingleStatJob.perform_later(user.id, date.to_s)
        jobs_scheduled += 1
      end
    end

    # Count jobs already in the owner_api queue (not yet finished)
    # These will be processed before our newly enqueued jobs
    existing_queued_jobs = SolidQueue::Job.where(queue_name: "owner_api", finished_at: nil).count

    # Each BackfillSingleStatJob triggers 2 API calls (batch 1 + batch 2)
    # Total API calls = existing jobs + (new jobs * 2)
    total_api_calls = existing_queued_jobs + (jobs_scheduled * 2)
    estimated_seconds = [ total_api_calls * SECONDS_PER_API_CALL, 1 ].max.to_i

    faction.update!(
      backfill_ends_at: Time.current + estimated_seconds.seconds,
      backfill_target_date: start_date.to_date
    )

    # Schedule cleanup job to clear backfill status when done
    ClearBackfillStatusJob.set(wait: estimated_seconds.seconds).perform_later(faction.id)

    Rails.logger.info("Scheduled #{jobs_scheduled} stat fetch jobs for faction #{faction.name} (#{existing_queued_jobs} jobs already queued), completing in ~#{estimated_seconds}s")
  end
end
