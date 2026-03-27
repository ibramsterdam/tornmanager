class BackfillPersonalStatsJob < ApplicationJob
  queue_as :faction

  SECONDS_PER_API_CALL = 1.1

  def perform(faction_id, start_date, end_date)
    faction = Faction.find(faction_id)
    api_key = faction.torn_api_key&.key || AdminCredentials.api_key
    users = faction.users.active.to_a
    dates = (start_date.to_date..end_date.to_date).to_a

    Rails.logger.info("Scheduling backfill for faction #{faction.name}: #{users.count} users, #{dates.size} days")

    jobs_scheduled = 0

    users.each do |user|
      existing_dates = user.personal_stat_snapshots
                           .where(date: dates.first..dates.last)
                           .pluck(:date)
                           .to_set

      dates.each do |date|
        next if existing_dates.include?(date)

        BackfillSingleStatJob.perform_later(user.id, date.to_s, faction_id: faction.id, api_key: api_key)
        jobs_scheduled += 1
      end
    end

    # Schedule cleanup job based on the faction's existing backfill ETA
    # (backfill_ends_at is already set by the controller at setup time)
    if faction.backfill_ends_at.present?
      wait_seconds = [ (faction.backfill_ends_at - Time.current).to_i, 1 ].max
      ClearBackfillStatusJob.set(wait: wait_seconds.seconds).perform_later(faction.id)
    end

    Rails.logger.info("Scheduled #{jobs_scheduled} stat fetch jobs for faction #{faction.name}")
  end
end
