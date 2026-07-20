require "test_helper"

class FetchPersonalStatsJobTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")

    @user = users(:bram)
    @user.update!(faction: @faction)
    @api_key = "FACTION_KEY_123"
    @stats_date = Date.new(2026, 2, 19)
    @batch1_stats = PersonalStatSnapshot::TRACKED_STATS_BATCH_1.values.index_with { |_| 100 }
      .merge(date: @stats_date)
    @batch2_stats = PersonalStatSnapshot::TRACKED_STATS_BATCH_2.values.index_with { |_| 200 }
      .merge(date: @stats_date)
  end

  test "uses the provided api key" do
    TornApi::User::PersonalStats.expects(:new)
      .with(@api_key, @user.torn_id, anything)
      .returns(stub(fetch: @batch1_stats))
      .at_least_once

    FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date)
  end

  test "batch 1 saves snapshot and chains batch 2 with api_key" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(@batch1_stats)

    assert_enqueued_with(job: FetchPersonalStatsJob, args: [ @user, { api_key: @api_key, batch: 2, stats_date: @stats_date } ]) do
      FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date)
    end

    snapshot = @user.personal_stat_snapshots.find_by(date: @stats_date)
    assert snapshot
    assert_equal 100, snapshot.drugs_xanax
  end

  test "batch 2 saves snapshot and does not chain further" do
    @user.personal_stat_snapshots.create!(date: @stats_date, drugs_xanax: 100)
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(@batch2_stats)

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 2, stats_date: @stats_date)
    end

    snapshot = @user.personal_stat_snapshots.find_by(date: @stats_date)
    assert_equal 200, snapshot.attacking_networth_money_mugged
  end

  test "marks user as hof_stats_user when stat enhancers exceed threshold" do
    stats_with_enhancers = @batch1_stats.merge(items_used_stat_enhancers: 500)
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(stats_with_enhancers)

    refute @user.hof_stats_user
    FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date)
    assert @user.reload.hof_stats_user
  end

  test "does not mark hof_stats_user when stat enhancers below threshold" do
    stats_low_enhancers = @batch1_stats.merge(items_used_stat_enhancers: 50)
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(stats_low_enhancers)

    FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date)
    refute @user.reload.hof_stats_user
  end

  test "hof eligibility check only runs on batch 1" do
    stats_with_enhancers = @batch2_stats.merge(items_used_stat_enhancers: 500)
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(stats_with_enhancers)
    @user.personal_stat_snapshots.create!(date: @stats_date)

    FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 2, stats_date: @stats_date)
    refute @user.reload.hof_stats_user
  end

  test "retries on InvalidKeyError" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "auth failed")

    assert_enqueued_with(job: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date, retries: 0)
    end
  end

  test "gives up after max retries on InvalidKeyError" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "auth failed")
    Discord::Notifier.expects(:notify).once

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date, retries: 3)
    end
  end

  test "no data from Torn is skipped quietly without retrying or paging" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::NoDataError, "No personal stats data returned")
    Discord::Notifier.expects(:notify).never

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date)
    end

    assert_not @user.personal_stat_snapshots.exists?(date: @stats_date),
      "nightly fetch must leave the date to the gap scan, not tombstone or save it"
  end

  test "inherits from TornApiJob via the FactionApiJob alias" do
    assert FetchPersonalStatsJob < FactionApiJob
    assert FetchPersonalStatsJob < TornApiJob
    assert_equal "torn_api", FetchPersonalStatsJob.new.queue_name
  end
end
