module Recruiter
  class BackfillMissingStatsJob < ApplicationJob
    queue_as :default

    NIGHTLY_CAP = 5_000
    STALE_AFTER = 14.days
    SECONDS_PER_API_CALL = 1.5
    MIN_COMPANY_RATING = 7

    def perform
      user_ids = User.employed
        .where(company_director: false)
        .where(company_id: Company.where(rating: MIN_COMPANY_RATING..).select(:torn_id))
        .where("working_stats IS NULL OR working_stats_at < ?", STALE_AFTER.ago)
        .order(:working_stats_at)
        .limit(NIGHTLY_CAP)
        .pluck(:id)

      user_ids.each_with_index do |user_id, index|
        FetchPlayerHofJob.set(wait: (index * SECONDS_PER_API_CALL).seconds).perform_later(user_id)
      end

      Rails.logger.info("Recruiter::BackfillMissingStatsJob: scheduled #{user_ids.size} fetches")
    end
  end
end
