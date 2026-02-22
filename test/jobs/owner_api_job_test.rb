require "test_helper"

class OwnerApiJobTest < ActiveJob::TestCase
  test "enqueues to the owner_api queue" do
    assert_equal "owner_api", OwnerApiJob.new.queue_name
  end

  test "subclasses inherit the owner_api queue" do
    assert_equal "owner_api", FetchPersonalStatsJob.new.queue_name
    assert_equal "owner_api", BackfillSingleStatJob.new.queue_name
    assert_equal "owner_api", SyncFactionMembersJob.new.queue_name
    assert_equal "owner_api", Daily::XanaxPaymentsJob.new.queue_name
    assert_equal "owner_api", Daily::StockDividendJob.new.queue_name
  end

  test "has a 1 second rate limit sleep constant" do
    assert_equal 1.0, OwnerApiJob::RATE_LIMIT_SLEEP
  end

  test "around_perform sleeps after execution" do
    # Use a concrete subclass with a no-op perform
    job_class = Class.new(OwnerApiJob) do
      def perform
        # no-op
      end
    end

    job = job_class.new
    job.expects(:sleep).with(1.0).once
    job.perform_now
  end

  test "rate limit math stays under 50 req per minute" do
    sleep_duration = OwnerApiJob::RATE_LIMIT_SLEEP
    polling_interval = 1.1 # from config/queue.yml

    cycle_time = sleep_duration + polling_interval
    max_requests_per_minute = 60.0 / cycle_time

    assert max_requests_per_minute < 50, "Expected < 50 req/min, got #{max_requests_per_minute.round(1)}"
  end
end
