require "test_helper"

# All jobs that hit the Torn API with the same api key must share ONE
# solid_queue semaphore, regardless of job class. Today FetchPersonalStatsJob
# serializes per api_key while the FactionApiCalls group serializes per
# faction_id — so several parallel streams can hammer the same key (worst on
# the kaneki key during HOF sync, where users span many faction_ids).
class TornApiConcurrencyTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")

    @user = users(:bram)
    @user.update!(faction: @faction)
  end

  test "personal stats and backfill jobs with the same api key share one semaphore" do
    personal_stats = FetchPersonalStatsJob.new(@user, api_key: "FACTION_KEY_123")
    backfill = BackfillSingleStatJob.new(@user.id, "2026-07-01", faction_id: @faction.id, api_key: "FACTION_KEY_123")

    assert_equal personal_stats.concurrency_key, backfill.concurrency_key
  end

  test "faction-scoped jobs serialize on the faction's api key, not the faction id" do
    expected = FetchPersonalStatsJob.new(@user, api_key: "FACTION_KEY_123").concurrency_key

    [
      FetchMemberActivityJob.new(@faction.id),
      FetchArmoryNewsJob.new(@faction.id),
      BackfillArmoryNewsJob.new(@faction.id),
      BackfillRankedWarsJob.new(@faction.id)
    ].each do |job|
      assert_equal expected, job.concurrency_key,
        "#{job.class} must share the per-key semaphore with FetchPersonalStatsJob"
    end
  end

  test "hof backfills without a faction still serialize on the shared key" do
    # This is the 04:30 incident: HOF users have faction_id nil (or an
    # uncovered faction), so faction_id-keyed semaphores let 5 worker threads
    # run in parallel on the single kaneki key.
    hof_backfill = BackfillSingleStatJob.new(@user.id, "2026-07-01", faction_id: nil, api_key: "KANEKI_KEY")
    hof_personal_stats = FetchPersonalStatsJob.new(@user, api_key: "KANEKI_KEY")

    assert_equal hof_personal_stats.concurrency_key, hof_backfill.concurrency_key
  end

  test "jobs with different api keys do not block each other" do
    a = FetchPersonalStatsJob.new(@user, api_key: "FACTION_KEY_123")
    b = FetchPersonalStatsJob.new(@user, api_key: "OTHER_KEY_456")

    assert_not_equal a.concurrency_key, b.concurrency_key
  end
end
