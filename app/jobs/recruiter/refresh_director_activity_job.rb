module Recruiter
  class RefreshDirectorActivityJob < ApplicationJob
    queue_as :default

    NIGHTLY_CAP = 5_000
    SECONDS_PER_API_CALL = 1.5
    STALE_AFTER = 2.days

    def perform
      torn_ids = Company
        .where.not(director_torn_id: nil)
        .joins("LEFT JOIN users directors ON directors.torn_id = companies.director_torn_id")
        .where("directors.id IS NULL OR directors.company_synced_at IS NULL OR directors.company_synced_at < ?", latest_roster_sync)
        .where("directors.last_action_at IS NULL OR directors.company_synced_at > datetime(directors.last_action_at, ?)", "+#{STALE_AFTER.in_days.to_i} days")
        .order(Arel.sql("directors.last_action_at IS NOT NULL"), :director_torn_id)
        .distinct
        .limit(NIGHTLY_CAP)
        .pluck(:director_torn_id)

      torn_ids.each_with_index do |torn_id, index|
        FetchDirectorActivityJob.set(wait: (index * SECONDS_PER_API_CALL).seconds).perform_later(torn_id)
      end

      Rails.logger.info("Recruiter::RefreshDirectorActivityJob: scheduled #{torn_ids.size} fetches")
    end

    private

    def latest_roster_sync
      Company.maximum(:synced_at) || Time.current
    end
  end
end
