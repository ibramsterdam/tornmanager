require "test_helper"

class AdminApiJobTest < ActiveJob::TestCase
  test "enqueues to the admin queue" do
    assert_equal "admin", AdminApiJob.new.queue_name
  end

  test "subclasses inherit the admin queue" do
    assert_equal "admin", SyncFactionMembersJob.new.queue_name
    assert_equal "admin", Daily::XanaxPaymentsJob.new.queue_name
    assert_equal "admin", Daily::StockDividendJob.new.queue_name
  end

  test "has a 1 second rate limit sleep constant" do
    assert_equal 1.0, AdminApiJob::RATE_LIMIT_SLEEP
  end

  test "around_perform sleeps after execution" do
    job_class = Class.new(AdminApiJob) do
      def perform
        # no-op
      end
    end

    job = job_class.new
    job.expects(:sleep).with(1.0).once
    job.perform_now
  end

  test "rate limit math stays under 50 req per minute" do
    sleep_duration = AdminApiJob::RATE_LIMIT_SLEEP
    polling_interval = 1.1

    cycle_time = sleep_duration + polling_interval
    max_requests_per_minute = 60.0 / cycle_time

    assert max_requests_per_minute < 50, "Expected < 50 req/min, got #{max_requests_per_minute.round(1)}"
  end
end
