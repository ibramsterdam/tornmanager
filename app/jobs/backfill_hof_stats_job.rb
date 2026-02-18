class BackfillHofStatsJob < ApplicationJob
  queue_as :default

  SECONDS_PER_API_CALL = 1.1

  def perform(start_date = nil, end_date = nil)
    start_date = (start_date || PersonalStatSnapshot.tracking_start_date).to_date
    end_date = (end_date || PersonalStatSnapshot.tracking_end_date).to_date

    users = User.hof_stats_users.to_a
    dates = (start_date..end_date).to_a

    Rails.logger.info("Scheduling HOF backfill: #{users.count} users, #{dates.size} days")

    jobs_scheduled = 0

    users.each_with_index do |user, user_index|
      dates.each_with_index do |date, date_index|
        delay = (user_index * dates.size) + date_index
        BackfillSingleStatJob.set(wait: delay.seconds).perform_later(user.id, date.to_s)
        jobs_scheduled += 1
      end
    end

    existing_queued_jobs = SolidQueue::Job.where(queue_name: "torn_api", finished_at: nil).count
    total_api_calls = existing_queued_jobs + (jobs_scheduled * 2)
    estimated_seconds = [ total_api_calls * SECONDS_PER_API_CALL, 1 ].max.to_i

    Rails.logger.info("Scheduled #{jobs_scheduled} HOF stat fetch jobs, completing in ~#{estimated_seconds}s")
  end
end
