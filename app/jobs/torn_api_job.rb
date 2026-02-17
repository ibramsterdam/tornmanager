# Base class for jobs that call the Torn API
# Automatically sleeps after execution to respect rate limits
class TornApiJob < ApplicationJob
  queue_as :torn_api

  # Sleep duration after each job to stay under 60 requests/minute
  RATE_LIMIT_SLEEP = 1.0

  around_perform do |_job, block|
    block.call
    sleep(RATE_LIMIT_SLEEP)
  end
end
