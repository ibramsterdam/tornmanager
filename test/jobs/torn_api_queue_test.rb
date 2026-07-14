require "test_helper"

# Queues express latency class, not key type: every Torn API worker shares one
# torn_api queue whose thread count bounds aggregate throughput (threads x ~40
# calls/min). Priority decides who goes next on a contended key's semaphore —
# solid_queue releases blocked executions by (priority, job_id), so a 15-minute
# activity poll never waits behind hundreds of queued backfills.
class TornApiQueueTest < ActiveJob::TestCase
  PRIORITY_INTERACTIVE = 0
  PRIORITY_RECURRING = 10
  PRIORITY_NIGHTLY = 50
  PRIORITY_BACKFILL = 100

  test "all torn api workers share the torn_api queue" do
    [
      FetchPersonalStatsJob,
      BackfillSingleStatJob,
      FetchMemberActivityJob,
      FetchArmoryNewsJob,
      BackfillArmoryNewsJob,
      BackfillRankedWarsJob,
      SyncFactionMembersJob,
      Daily::XanaxPaymentsJob,
      Daily::StockDividendJob
    ].each do |job_class|
      assert_equal "torn_api", job_class.new.queue_name,
        "#{job_class} must run on the torn_api queue"
    end
  end

  test "the base aliases route to torn_api during migration" do
    assert_equal "torn_api", FactionApiJob.new.queue_name
    assert_equal "torn_api", AdminApiJob.new.queue_name
  end

  test "war polling keeps its own latency-sensitive queue" do
    assert_equal "war", WarPollingJob.new.queue_name
    assert_equal "war", PublicWarPollingJob.new.queue_name
  end

  test "recurring polls outrank nightly work on a contended key" do
    assert_equal PRIORITY_RECURRING, FetchMemberActivityJob.new.priority
    assert_equal PRIORITY_NIGHTLY, FetchPersonalStatsJob.new.priority
  end

  test "backfills always yield to everything else" do
    [ BackfillSingleStatJob, BackfillArmoryNewsJob, BackfillRankedWarsJob ].each do |job_class|
      assert_equal PRIORITY_BACKFILL, job_class.new.priority,
        "#{job_class} must carry backfill priority"
    end
  end

  test "torn api jobs default to interactive priority" do
    assert_equal PRIORITY_INTERACTIVE, TornApiJob.new.priority
  end
end
