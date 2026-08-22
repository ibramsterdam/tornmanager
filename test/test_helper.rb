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

    # A snapshot with every tracked stat filled — rows with any nil column
    # count as "partial" and are re-fetched by the nightly gap scan.
    def create_complete_snapshot(user, date)
      attrs = PersonalStatSnapshot::TRACKED_STATS.values.index_with { 1 }
      user.personal_stat_snapshots.find_or_create_by!(date: date) do |s|
        s.assign_attributes(attrs)
      end
    end

    # Bearer auth headers for userscript API requests
    def api_auth(user)
      { "Authorization" => "Bearer #{user.api_token}" }
    end

    # Helper to grant a subscription to a user or faction via the Subscription model
    def grant_subscription(subscribable, expires_at:)
      sub = subscribable.subscription || subscribable.build_subscription
      sub.update!(expires_at: expires_at)
      sub
    end
  end
end
