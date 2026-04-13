module Daily
  class HofMemberSyncJob < ApplicationJob
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

    def backfill_gaps(user, api_key)
      existing = user.personal_stat_snapshots.pluck(:date).to_set
      expected = (PersonalStatSnapshot.tracking_start_date..PersonalStatSnapshot.tracking_end_date).to_a
      yesterday = Date.current.yesterday

      missing = expected.reject { |d| existing.include?(d) || d == yesterday }
      return if missing.empty?

      missing.each do |date|
        BackfillSingleStatJob.perform_later(user.id, date.to_s, faction_id: user.faction_id, api_key: api_key)
      end
    end

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
