class BackfillUserStatsJob < ApplicationJob
  queue_as :faction

  def perform(user_id, start_date, end_date, api_key: nil)
    user = User.find(user_id)
    api_key ||= user.faction&.torn_api_key&.key
    return Rails.logger.warn("BackfillUserStatsJob: No API key for #{user.name}, skipping") unless api_key

    dates = (start_date.to_date..end_date.to_date).to_a

    existing_dates = user.personal_stat_snapshots
                         .where(date: dates.first..dates.last)
                         .pluck(:date)
                         .to_set

    jobs_scheduled = 0
    dates.each do |date|
      next if existing_dates.include?(date)

      BackfillSingleStatJob.perform_later(user.id, date.to_s, faction_id: user.faction_id, api_key: api_key)
      jobs_scheduled += 1
    end

    Rails.logger.info("BackfillUserStatsJob: Scheduled #{jobs_scheduled} jobs for #{user.name}")
  end
end
