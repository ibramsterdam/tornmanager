class BackfillPersonalStatsJob < ApplicationJob
  queue_as :default

  def perform(faction_id, start_date, end_date)
    faction = Faction.find(faction_id)

    Rails.logger.info("Scheduling backfill for faction #{faction.name}: #{faction.users.count} users")

    delay = 0.seconds
    jobs_scheduled = 0

    faction.users.find_each do |user|
      BackfillUserStatsJob.set(wait: delay).perform_later(user.id, start_date, end_date)
      delay += 1.second
      jobs_scheduled += 1
    end

    Rails.logger.info("Scheduled #{jobs_scheduled} user backfill jobs for faction #{faction.name}")
  end
end
