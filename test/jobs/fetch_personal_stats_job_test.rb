require "test_helper"

class FetchPersonalStatsJobTest < ActiveJob::TestCase
  setup do
    @user = users(:bram)
    @stats_date = Date.new(2026, 2, 19)
    @batch1_stats = PersonalStatSnapshot::TRACKED_STATS_BATCH_1.values.index_with { |_| 100 }
      .merge(date: @stats_date)
    @batch2_stats = PersonalStatSnapshot::TRACKED_STATS_BATCH_2.values.index_with { |_| 200 }
      .merge(date: @stats_date)
    AdminCredentials.stubs(:api_key).returns("test_key")
  end

  test "batch 1 saves snapshot and chains batch 2" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(@batch1_stats)

    assert_enqueued_with(job: FetchPersonalStatsJob, args: [ @user, { batch: 2, stats_date: @stats_date } ]) do
      FetchPersonalStatsJob.perform_now(@user, batch: 1, stats_date: @stats_date)
    end

    snapshot = @user.personal_stat_snapshots.find_by(date: @stats_date)
    assert snapshot, "Expected a snapshot to be saved"
    assert_equal 100, snapshot.drugs_xanax
  end

  test "batch 2 saves snapshot and does not chain further" do
    # Create initial snapshot from batch 1
    @user.personal_stat_snapshots.create!(date: @stats_date, drugs_xanax: 100)

    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(@batch2_stats)

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, batch: 2, stats_date: @stats_date)
    end

    snapshot = @user.personal_stat_snapshots.find_by(date: @stats_date)
    assert_equal 200, snapshot.attacking_networth_money_mugged
  end

  test "marks user as hof_stats_user when stat enhancers exceed threshold" do
    stats_with_enhancers = @batch1_stats.merge(items_used_stat_enhancers: 500)
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(stats_with_enhancers)

    refute @user.hof_stats_user

    FetchPersonalStatsJob.perform_now(@user, batch: 1, stats_date: @stats_date)

    assert @user.reload.hof_stats_user
  end

  test "does not mark hof_stats_user when stat enhancers below threshold" do
    stats_low_enhancers = @batch1_stats.merge(items_used_stat_enhancers: 50)
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(stats_low_enhancers)

    FetchPersonalStatsJob.perform_now(@user, batch: 1, stats_date: @stats_date)

    refute @user.reload.hof_stats_user
  end

  test "retries on InvalidKeyError" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "auth failed")

    assert_enqueued_with(job: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, batch: 1, stats_date: @stats_date, retries: 0)
    end
  end

  test "gives up after max retries on InvalidKeyError" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "auth failed")
    Discord::Notifier.expects(:notify).once

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, batch: 1, stats_date: @stats_date, retries: 3)
    end
  end

  test "hof eligibility check only runs on batch 1" do
    stats_with_enhancers = @batch2_stats.merge(items_used_stat_enhancers: 500)
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(stats_with_enhancers)
    @user.personal_stat_snapshots.create!(date: @stats_date)

    FetchPersonalStatsJob.perform_now(@user, batch: 2, stats_date: @stats_date)

    refute @user.reload.hof_stats_user, "Batch 2 should not check HoF eligibility"
  end
end
