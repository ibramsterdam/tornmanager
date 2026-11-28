module Recruiter
  class FetchDirectorActivityJob < TornApiJob
    queue_with_priority 100
    limits_concurrency to: 1, key: "recruiter", group: CONCURRENCY_GROUP

    def perform(torn_id)
      api_key = KeyPool.next_key
      return Rails.logger.warn("Recruiter::FetchDirectorActivityJob: no recruiter api key, skipping") unless api_key

      result = TornApi::User::LastAction.new(api_key, torn_id).fetch
      return unless result.last_action_at

      User.upsert(
        { torn_id: result.torn_id, name: result.name, level: result.level, last_action_at: result.last_action_at },
        unique_by: :torn_id,
        update_only: [ :name, :level, :last_action_at ],
        record_timestamps: true
      )
    rescue TornApi::NotFoundError
      Rails.logger.info("Recruiter::FetchDirectorActivityJob: director #{torn_id} not found")
    end
  end
end
