require "test_helper"

class BackfillSingleStatJobTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(torn_id: 77777, name: "Test Faction", xanax_target: 2.5)
    @user = users(:bram)
    @user.update!(faction: @faction)
    @date_str = "2026-01-15"
    @batch1_stats = PersonalStatSnapshot::TRACKED_STATS_BATCH_1.values.index_with { |_| 42 }
      .merge(date: Date.parse(@date_str))
  end

  test "batch 1 saves snapshot and chains batch 2 with api_key" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(@batch1_stats)

    assert_enqueued_with(job: BackfillSingleStatJob, args: [ @user.id, @date_str, { faction_id: @faction.id, batch: 2, api_key: "test_key" } ]) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, batch: 1, api_key: "test_key")
    end

    snapshot = @user.personal_stat_snapshots.find_by(date: @date_str)
    assert snapshot, "Expected snapshot to be saved"
    assert_equal 42, snapshot.drugs_xanax
  end

  test "batch 2 does not chain further" do
    @user.personal_stat_snapshots.create!(date: @date_str, drugs_xanax: 42)

    batch2_stats = PersonalStatSnapshot::TRACKED_STATS_BATCH_2.values.index_with { |_| 99 }
      .merge(date: Date.parse(@date_str))
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(batch2_stats)

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, batch: 2, api_key: "test_key")
    end
  end

  test "skips when no api_key passed" do
    assert_nothing_raised do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id)
    end

    assert_nil @user.personal_stat_snapshots.find_by(date: @date_str)
  end

  test "handles API error gracefully without saving snapshot" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).raises(TornApi::ApiError, "Rate limited")

    assert_nothing_raised do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, api_key: "test_key")
    end

    assert_nil @user.personal_stat_snapshots.find_by(date: @date_str)
  end

  test "chains batch 2 with the same api_key" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(@batch1_stats)

    assert_enqueued_with(job: BackfillSingleStatJob, args: [ @user.id, @date_str, { faction_id: @faction.id, batch: 2, api_key: "faction_key_123" } ]) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, batch: 1, api_key: "faction_key_123")
    end
  end
end

class BackfillPersonalStatsJobTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(
      torn_id: 77777, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0
    )
    @faction.create_faction_setting!
    ApiKey::Torn.create!(faction: @faction, key: "faction_api_key_abc", access_type: "Limited Access")
    @user = users(:bram)
    @user.update!(faction: @faction)
  end

  test "passes faction api_key to BackfillSingleStatJob" do
    start_date = Date.new(2026, 2, 20)
    end_date = Date.new(2026, 2, 20)

    assert_enqueued_with(
      job: BackfillSingleStatJob,
      args: [ @user.id, "2026-02-20", { faction_id: @faction.id, api_key: "faction_api_key_abc" } ]
    ) do
      BackfillPersonalStatsJob.perform_now(@faction.id, start_date.to_s, end_date.to_s)
    end
  end

  test "skips when faction has no api key" do
    @faction.api_keys.destroy_all
    @faction.reload

    start_date = Date.new(2026, 2, 20)
    end_date = Date.new(2026, 2, 20)

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      BackfillPersonalStatsJob.perform_now(@faction.id, start_date.to_s, end_date.to_s)
    end
  end

  test "does not recalculate backfill_ends_at (already set by controller)" do
    @faction.update!(
      backfill_ends_at: 1.hour.from_now,
      backfill_target_date: Date.new(2026, 1, 1)
    )
    original_ends_at = @faction.backfill_ends_at

    start_date = Date.new(2026, 2, 20)
    end_date = Date.new(2026, 2, 20)

    BackfillPersonalStatsJob.perform_now(@faction.id, start_date.to_s, end_date.to_s)

    @faction.reload
    assert_equal original_ends_at.to_i, @faction.backfill_ends_at.to_i
  end
end
