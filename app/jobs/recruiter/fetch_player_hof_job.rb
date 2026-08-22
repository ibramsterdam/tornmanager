module Recruiter
  class FetchPlayerHofJob < TornApiJob
    queue_with_priority 100
    limits_concurrency to: 1, key: "recruiter", group: CONCURRENCY_GROUP

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      api_key = KeyPool.next_key
      return Rails.logger.warn("Recruiter::FetchPlayerHofJob: no recruiter api key, skipping") unless api_key

      value = TornApi::User::Hof.new(api_key, user.torn_id).fetch
      user.update!(working_stats: value || 0, working_stats_at: Time.current)
    rescue TornApi::NotFoundError
      user.update!(working_stats: 0, working_stats_at: Time.current)
    end
  end
end
