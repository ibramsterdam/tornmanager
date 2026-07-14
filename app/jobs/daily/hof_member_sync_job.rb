module Daily
  class HofMemberSyncJob < ApplicationJob
    include GapBackfill

    queue_as :default

    def perform
      api_key = Rails.application.credentials.dig(:kaneki, :api_key)
      return Rails.logger.warn("[HofMemberSync] No kaneki API key configured, skipping") unless api_key

      hof_users_without_faction_key.find_each do |user|
        FetchPersonalStatsJob.perform_later(user, api_key: api_key)
        backfill_gaps(user, api_key)
      end
    end

    private

    def hof_users_without_faction_key
      covered_faction_ids = Faction
        .joins(:api_keys)
        .where(setup_completed: true, api_keys: { type: "ApiKey::Torn" })
        .pluck(:id)

      base = User.where(hof_stats_user: true, fallen: false)

      if covered_faction_ids.any?
        base.where(faction_id: nil).or(base.where.not(faction_id: covered_faction_ids))
      else
        base
      end
    end
  end
end
