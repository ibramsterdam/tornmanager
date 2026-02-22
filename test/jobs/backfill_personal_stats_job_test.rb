require "test_helper"

class BackfillSingleStatJobTest < ActiveJob::TestCase
  setup do
    @user = users(:bram)
    @date_str = "2026-01-15"
    @batch1_stats = PersonalStatSnapshot::TRACKED_STATS_BATCH_1.values.index_with { |_| 42 }
      .merge(date: Date.parse(@date_str))
  end

  test "batch 1 saves snapshot and chains batch 2" do
    OwnerCredentials.stubs(:api_key).returns("test_key")
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(@batch1_stats)

    assert_enqueued_with(job: BackfillSingleStatJob, args: [ @user.id, @date_str, { batch: 2 } ]) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, batch: 1)
    end

    snapshot = @user.personal_stat_snapshots.find_by(date: @date_str)
    assert snapshot, "Expected snapshot to be saved"
    assert_equal 42, snapshot.drugs_xanax
  end

  test "batch 2 does not chain further" do
    OwnerCredentials.stubs(:api_key).returns("test_key")
    @user.personal_stat_snapshots.create!(date: @date_str, drugs_xanax: 42)

    batch2_stats = PersonalStatSnapshot::TRACKED_STATS_BATCH_2.values.index_with { |_| 99 }
      .merge(date: Date.parse(@date_str))
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(batch2_stats)

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, batch: 2)
    end
  end

  test "logs error and returns when api key is blank" do
    OwnerCredentials.stubs(:api_key).returns(nil)

    assert_nothing_raised do
      BackfillSingleStatJob.perform_now(@user.id, @date_str)
    end

    assert_nil @user.personal_stat_snapshots.find_by(date: @date_str)
  end

  test "handles API error gracefully without saving snapshot" do
    OwnerCredentials.stubs(:api_key).returns("test_key")
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).raises(TornApi::ApiError, "Rate limited")

    assert_nothing_raised do
      BackfillSingleStatJob.perform_now(@user.id, @date_str)
    end

    assert_nil @user.personal_stat_snapshots.find_by(date: @date_str)
  end
end
