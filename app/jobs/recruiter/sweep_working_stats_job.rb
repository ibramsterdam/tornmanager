module Recruiter
  class SweepWorkingStatsJob < TornApiJob
    queue_with_priority 50
    limits_concurrency to: 1, key: "recruiter", group: CONCURRENCY_GROUP

    VALUE_FLOOR = 5_000
    MAX_PAGES = 600
    PAGE_SIZE = TornApi::Torn::HofLeaderboard::PAGE_SIZE
    BUDGET_COOLDOWN = 65.seconds
    MAX_COOLDOWNS_PER_PAGE = 10

    def perform
      api_key = KeyPool.next_key
      return Rails.logger.warn("Recruiter::SweepWorkingStatsJob: no recruiter api key, skipping") unless api_key

      swept_at = Time.current
      updated = 0

      MAX_PAGES.times do |page|
        rows = fetch_page(api_key, page)
        break if rows.empty?

        updated += apply(rows, swept_at)
        break if rows.size < PAGE_SIZE || rows.last.value < VALUE_FLOOR

        sleep(RATE_LIMIT_SLEEP)
      end

      Rails.logger.info("Recruiter::SweepWorkingStatsJob: updated #{updated} users")
    end

    private

    def fetch_page(api_key, page)
      cooldowns = 0
      begin
        TornApi::Torn::HofLeaderboard.new(api_key, offset: page * PAGE_SIZE).fetch
      rescue TornApi::RateLimitError
        cooldowns += 1
        raise if cooldowns > MAX_COOLDOWNS_PER_PAGE

        Rails.logger.info("Recruiter::SweepWorkingStatsJob: key budget spent, cooling down at page #{page}")
        sleep(BUDGET_COOLDOWN)
        retry
      end
    end

    def apply(rows, swept_at)
      User.transaction do
        rows.count do |row|
          User.where(torn_id: row.torn_id).update_all(working_stats: row.value, working_stats_at: swept_at) == 1
        end
      end
    end
  end
end
