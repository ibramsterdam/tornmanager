class BackfillHofStatsJob < ApplicationJob
  queue_as :default

  # Seconds per API call (polling_interval of torn_api queue)
  SECONDS_PER_API_CALL = 1.1

  def perform(start_date, end_date)
    users = User.hof_stats_users.to_a
    dates = (start_date.to_date..end_date.to_date).to_a

    Rails.logger.info("Scheduling HOF backfill: #{users.count} users, #{dates.size} days")

    jobs_scheduled = 0

    users.each do |user|
      existing_snapshots = user.personal_stat_snapshots
                              .where(timestamp: dates.first.to_time.to_i..dates.last.end_of_day.to_i)
                              .pluck(:timestamp)
                              .map { |ts| Time.at(ts).utc.to_date }
                              .to_set

      dates.each do |date|
        next if existing_snapshots.include?(date)

        BackfillSingleStatJob.perform_later(user.id, date.to_s)
        jobs_scheduled += 1
      end
    end

    existing_queued_jobs = SolidQueue::Job.where(queue_name: "torn_api", finished_at: nil).count
    total_api_calls = existing_queued_jobs + (jobs_scheduled * 2)
    estimated_seconds = [ total_api_calls * SECONDS_PER_API_CALL, 1 ].max.to_i

    Rails.logger.info("Scheduled #{jobs_scheduled} HOF stat fetch jobs (#{existing_queued_jobs} jobs already queued), completing in ~#{estimated_seconds}s")
  end
end
