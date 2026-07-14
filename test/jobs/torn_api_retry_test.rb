require "test_helper"

# Rate limits heal in ~60 seconds, so a rate-limited job must be retried with
# a delay instead of failing permanently (which loses the day's snapshot and
# feeds tomorrow's backfill load). Same for transient Torn-side errors
# (5xx, empty personalstats payloads, "backend error, please try again").
class TornApiRetryTest < ActiveJob::TestCase
  class RateLimitedAdminJob < AdminApiJob
    def perform
      raise TornApi::RateLimitError, "Too many requests"
    end
  end

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
  end

  test "a rate-limited personal stats fetch is retried instead of failing" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::RateLimitError, "Too many requests")

    assert_enqueued_with(job: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date)
    end
  end

  test "the rate limit retry is scheduled with a delay, not immediately" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::RateLimitError, "Too many requests")

    freeze_time do
      FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date)

      retry_job = enqueued_jobs.last
      assert retry_job[:at].present?, "retry must be scheduled in the future"
      assert retry_job[:at] >= 60.seconds.from_now.to_f,
        "retry must wait at least a minute for the rate limit window to reset"
    end
  end

  test "gives up and re-raises after exhausting rate limit retries" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::RateLimitError, "Too many requests")

    job = FetchPersonalStatsJob.new(@user, api_key: @api_key, batch: 1, stats_date: @stats_date)
    job.executions = 4
    job.exception_executions = { "[TornApi::RateLimitError]" => 4 }

    assert_raises(TornApi::RateLimitError) { job.perform_now }
  end

  test "transient torn errors are retried instead of failing" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::TransientError, "No personal stats data returned")

    assert_enqueued_with(job: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date)
    end
  end

  test "admin api jobs also retry on rate limits" do
    assert_enqueued_with(job: RateLimitedAdminJob) do
      RateLimitedAdminJob.perform_now
    end
  end

  test "invalid key errors keep the existing manual retry path" do
    TornApi::User::PersonalStats.any_instance.stubs(:fetch)
      .raises(TornApi::InvalidKeyError, "auth failed")

    assert_enqueued_with(job: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, api_key: @api_key, batch: 1, stats_date: @stats_date, retries: 0)
    end
  end
end
