require "test_helper"

class WarPollingJobTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test Faction", track_stats: true, xanax_target: 2.5, war_polling_active: true)
    @faction.create_faction_setting!(torn_api_key: "faction_limited_key", torn_api_access_type: "Limited Access")

    @war = @faction.ranked_wars.create!(
      torn_war_id: 1001,
      opponent_faction_id: 88888,
      opponent_faction_name: "Enemy Faction",
      started_at: 1.hour.ago,
      target_score: 100,
      our_score: 30,
      their_score: 20
    )

    @enemy_member = TornApi::Faction::Members::Member.new(
      5555555, "EnemyPlayer", 40, 30,
      "Online", 1708000000, "2 minutes ago",
      "In hospital for 1 hour", "", "Hospital", "red", (Time.current + 1.hour).to_i, nil,
      "Everyone", "Member", true, false, false, false
    )
  end

  test "writes war data to cache" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @enemy_member ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      assert_not_nil cached
      assert_equal 88888, cached[:enemy_faction_id]
      assert_equal "Enemy Faction", cached[:enemy_faction_name]
      assert_equal 30, cached[:our_score]
      assert_equal 20, cached[:their_score]
      assert_equal 100, cached[:target_score]
      assert cached[:members].key?(5555555)
    end
  end

  test "merges spy reports into cached data" do
    @faction.spy_reports.create!(
      torn_id: 5555555,
      strength: 100_000,
      defense: 200_000,
      speed: 50_000,
      dexterity: 50_000,
      total: 400_000,
      spied_at: 1.day.ago
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @enemy_member ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      member_data = cached[:members][5555555]
      assert_equal 400_000, member_data[:stats][:total]
      assert_not_nil member_data[:stats_timestamp]
    end
  end

  test "includes member status in cached data" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @enemy_member ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      member_data = cached[:members][5555555]
      assert_equal "Hospital", member_data[:status][:state]
    end
  end

  test "re-enqueues itself after completing" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @enemy_member ])

    with_memory_cache do
      assert_enqueued_with(job: WarPollingJob, args: [ @faction.id ]) do
        WarPollingJob.perform_now(@faction.id)
      end
    end
  end

  test "stops when war_polling_active is false" do
    @faction.update!(war_polling_active: false)

    assert_no_enqueued_jobs(only: WarPollingJob) do
      WarPollingJob.perform_now(@faction.id)
    end
  end

  test "stops and deactivates when no active war exists" do
    @war.update!(ended_at: 1.minute.ago, winner_faction_id: 99999)

    with_memory_cache do
      assert_no_enqueued_jobs(only: WarPollingJob) do
        WarPollingJob.perform_now(@faction.id)
      end
    end

    assert_not @faction.reload.war_polling_active?
  end

  test "stops when no faction API key configured" do
    @faction.faction_setting.update!(torn_api_key: nil)

    assert_no_enqueued_jobs(only: WarPollingJob) do
      WarPollingJob.perform_now(@faction.id)
    end
  end

  test "re-enqueues on API error" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).raises(TornApi::ApiError, "Rate limited")

    with_memory_cache do
      assert_enqueued_with(job: WarPollingJob, args: [ @faction.id ]) do
        WarPollingJob.perform_now(@faction.id)
      end
    end
  end

  test "returns early for non-existent faction" do
    assert_nothing_raised do
      WarPollingJob.perform_now(0)
    end
  end

  private

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end
end
