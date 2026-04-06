ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper to grant a subscription to a user or faction via the Subscription model
    def grant_subscription(subscribable, expires_at:)
      sub = subscribable.subscription || subscribable.build_subscription
      sub.update!(expires_at: expires_at)
      sub
    end
  end
end
