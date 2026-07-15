# Base class for every job that calls the Torn API. API discipline lives here
# exactly once:
#
#   1. Serialize — subclasses declare `limits_concurrency` in CONCURRENCY_GROUP
#      keyed by the api key, so each key has ONE job in flight cluster-wide.
#      On a contended key, solid_queue releases blocked jobs by priority:
#      0 interactive · 10 recurring polls · 50 nightly · 100 backfill.
#   2. Pace — the 1s sleep keeps a serialized stream at ~38 calls/min, safely
#      under the 50/min per-key budget TornApi::RateLimiter enforces.
#   3. Retry — rate limits heal in a minute, Torn hiccups heal in a few;
#      both re-schedule instead of failing (and feeding tomorrow's backfill).
class TornApiJob < ApplicationJob
  queue_as :torn_api
  queue_with_priority 0

  CONCURRENCY_GROUP = "TornApiCalls"

  # Concurrency key for jobs that receive a faction_id instead of an api key.
  FACTION_KEY_LOOKUP = ->(faction_id, *, **) { Faction.find_by(id: faction_id)&.torn_api_key&.key }

  # 1.0s paced a stream at ~46 calls/min — close enough to the 50/min budget
  # that batch chains and activity polls on the same key tripped it nightly.
  # 1.5s paces at ~31/min, leaving genuine headroom.
  RATE_LIMIT_SLEEP = 1.5

  retry_on TornApi::RateLimitError, wait: 2.minutes, attempts: 5
  retry_on TornApi::TransientError, wait: 15.minutes, attempts: 3

  around_perform do |_job, block|
    block.call
    sleep(RATE_LIMIT_SLEEP)
  end
end
