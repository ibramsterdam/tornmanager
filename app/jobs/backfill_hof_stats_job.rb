class BackfillHofStatsJob < ApplicationJob
  queue_as :faction

  SECONDS_PER_API_CALL = 1.1

  def perform(start_date = nil, end_date = nil)
    api_key = Rails.application.credentials.dig(:kaneki, :api_key)
    return Rails.logger.warn("BackfillHofStatsJob: No kaneki API key configured, skipping") unless api_key

    start_date = (start_date || PersonalStatSnapshot.tracking_start_date).to_date
    end_date = (end_date || PersonalStatSnapshot.tracking_end_date).to_date

    users = User.hof_stats_users.to_a
    dates = (start_date..end_date).to_a

    Rails.logger.info("Scheduling HOF backfill: #{users.count} users, #{dates.size} days")

    jobs_scheduled = 0

    users.each_with_index do |user, user_index|
      dates.each_with_index do |date, date_index|
        delay = (user_index * dates.size) + date_index
        BackfillSingleStatJob.set(wait: delay.seconds).perform_later(user.id, date.to_s, faction_id: user.faction_id, api_key: api_key)
        jobs_scheduled += 1
      end
    end

    Rails.logger.info("BackfillHofStatsJob: Scheduled #{jobs_scheduled} jobs")
  end
end
