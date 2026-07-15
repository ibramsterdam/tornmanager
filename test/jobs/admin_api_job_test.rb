require "test_helper"

class AdminApiJobTest < ActiveJob::TestCase
  test "routes to the shared torn_api queue" do
    assert_equal "torn_api", AdminApiJob.new.queue_name
  end

  test "subclasses inherit the torn_api queue" do
    assert_equal "torn_api", SyncFactionMembersJob.new.queue_name
    assert_equal "torn_api", Daily::XanaxPaymentsJob.new.queue_name
    assert_equal "torn_api", Daily::StockDividendJob.new.queue_name
  end

  test "pacing sleep leaves real headroom under the per-key budget" do
    # 1.0s pacing produced ~46 calls/min in production - close enough to the
    # 50/min budget that batch chains and activity polls tripped it nightly.
    assert_operator AdminApiJob::RATE_LIMIT_SLEEP, :>=, 1.5
  end

  test "around_perform sleeps after execution" do
    job_class = Class.new(AdminApiJob) do
      def perform
        # no-op
      end
    end

    job = job_class.new
    job.expects(:sleep).with(AdminApiJob::RATE_LIMIT_SLEEP).once
    job.perform_now
  end

  test "pacing keeps a single stream under the per-key budget" do
    sleep_duration = AdminApiJob::RATE_LIMIT_SLEEP
    api_call_time = 0.5

    cycle_time = sleep_duration + api_call_time
    max_requests_per_minute = 60.0 / cycle_time

    assert max_requests_per_minute < TornApi::RateLimiter::REQUESTS_PER_MINUTE,
      "Expected < #{TornApi::RateLimiter::REQUESTS_PER_MINUTE} req/min, got #{max_requests_per_minute.round(1)}"
  end
end
