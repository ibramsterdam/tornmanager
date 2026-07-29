# Base class for every job that calls the Torn API: one job in flight per api
# key cluster-wide, paced under the budget TornApi::RateLimiter enforces.
# Queue priorities: 0 interactive · 10 recurring polls · 50 nightly · 100 backfill.
class TornApiJob < ApplicationJob
  queue_as :torn_api
  queue_with_priority 0

  CONCURRENCY_GROUP = "TornApiCalls"

  FACTION_KEY_LOOKUP = ->(faction_id, *, **) { Faction.find_by(id: faction_id)&.torn_api_key&.key }

  # 1.0s paced ~46 calls/min and tripped the 50/min budget nightly; 1.5s leaves headroom.
  RATE_LIMIT_SLEEP = 1.5

  retry_on TornApi::RateLimitError, wait: 2.minutes, attempts: 5
  retry_on TornApi::TransientError, wait: 15.minutes, attempts: 3

  around_perform do |_job, block|
    TornApi::RateLimiter.reserving_headroom_for_live_traffic { block.call }
    sleep(RATE_LIMIT_SLEEP)
  end
end
