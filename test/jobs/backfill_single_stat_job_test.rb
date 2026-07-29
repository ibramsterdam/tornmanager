require "test_helper"

class BackfillSingleStatJobTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")

    @user = users(:bram)
    @user.update!(faction: @faction)
    @date_str = "2026-07-01"
    @stats = PersonalStatSnapshot::TRACKED_STATS_BATCH_1.values.index_with { |_| 100 }
      .merge(date: Date.parse(@date_str))
  end

  test "saves the snapshot and chains batch 2 on success" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(@stats)

    assert_enqueued_with(job: BackfillSingleStatJob) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, api_key: "FACTION_KEY_123")
    end

    assert @user.personal_stat_snapshots.exists?(date: Date.parse(@date_str))
  end

  test "batch 2 completes the chain without enqueueing further work" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch).returns(@stats)

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, batch: 2, api_key: "FACTION_KEY_123")
    end

    assert @user.personal_stat_snapshots.exists?(date: Date.parse(@date_str))
  end

  test "a missing api key skips the date without touching the API" do
    TornApi::User::PersonalStats.any_instance.expects(:fetch).never

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id)
    end

    assert_not @user.personal_stat_snapshots.exists?(date: Date.parse(@date_str))
  end

  test "rate limit errors propagate so the job retries instead of losing the date" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::RateLimitError, "Too many requests")

    assert_enqueued_with(job: BackfillSingleStatJob) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, api_key: "FACTION_KEY_123")
    end

    assert_not @user.personal_stat_snapshots.exists?(date: Date.parse(@date_str))
  end

  test "a date torn has no data for gets a tombstone instead of endless retries" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::NoDataError, "No personal stats data returned")

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, api_key: "FACTION_KEY_123")
    end

    tombstone = @user.personal_stat_snapshots.find_by(date: Date.parse(@date_str))
    assert tombstone, "tombstone row must exist so the gap scan stops re-fetching"
    assert tombstone.torn_data_missing?
    assert_not PersonalStatSnapshot.partial.exists?(id: tombstone.id),
      "tombstones must not count as partial rows"
  end

  test "exhausted rate-limit retries drop quietly instead of paging" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::RateLimitError, "Too many requests")
    Discord::Notifier.expects(:notify).never

    job = BackfillSingleStatJob.new(@user.id, @date_str, faction_id: @faction.id, api_key: "FACTION_KEY_123")
    # Spend the retry budget so the next failure runs the give-up block.
    job.exception_executions = { "[TornApi::RateLimitError]" => 15 }

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      assert_nothing_raised { job.perform_now }
    end

    assert_not @user.personal_stat_snapshots.exists?(date: Date.parse(@date_str)),
      "a rate-limited backfill leaves the date for the nightly gap scan"
  end

  test "transient errors propagate so the job retries" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::TransientError, "Torn backend error, please try again")

    assert_enqueued_with(job: BackfillSingleStatJob) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, api_key: "FACTION_KEY_123")
    end
  end

  test "not found errors skip the date without retrying" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::NotFoundError, "Requested data is private")

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, api_key: "FACTION_KEY_123")
    end
  end

  test "invalid key errors skip the date without retrying" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::InvalidKeyError, "Invalid API key")

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      BackfillSingleStatJob.perform_now(@user.id, @date_str, faction_id: @faction.id, api_key: "FACTION_KEY_123")
    end
  end
end
