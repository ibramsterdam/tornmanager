class AdminApiJob < ApplicationJob
  queue_as :admin

  RATE_LIMIT_SLEEP = 1.0

  around_perform do |_job, block|
    block.call
    sleep(RATE_LIMIT_SLEEP)
  end
end
