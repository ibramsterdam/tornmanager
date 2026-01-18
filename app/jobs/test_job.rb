class TestJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.error("cake")
    # Do something later
  end
end
