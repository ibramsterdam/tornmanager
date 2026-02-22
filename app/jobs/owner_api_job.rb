# Base class for jobs that use the application owner's API key.
# All jobs on the owner_api queue run sequentially with a sleep
# between executions to respect the Torn API rate limit of 100 req/min.
# Combined with the queue's polling_interval of 1.1s, this keeps us
# well under 50 req/min.
class OwnerApiJob < ApplicationJob
  queue_as :owner_api

  # Sleep duration after each job execution
  RATE_LIMIT_SLEEP = 1.0

  around_perform do |_job, block|
    block.call
    sleep(RATE_LIMIT_SLEEP)
  end
end
