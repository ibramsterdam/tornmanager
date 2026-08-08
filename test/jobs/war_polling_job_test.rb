require "test_helper"

class WarPollingJobTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test Faction", xanax_target: 2.5, war_polling_active: true)
    @faction.create_faction_setting!
    ApiKey::Torn.create!(faction: @faction, key: "faction_limited_key", access_type: "Limited Access")

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

    TornApi::Faction::RankedWars.any_instance.stubs(:fetch).returns([])
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

  test "refreshes live war scores from rankedwars on every poll" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @enemy_member ])
    TornApi::Faction::RankedWars.any_instance.stubs(:fetch).returns([
      {
        "id" => 1001,
        "factions" => [
          { "id" => 99999, "name" => "Test Faction", "score" => 45 },
          { "id" => 88888, "name" => "Enemy Faction", "score" => 33 }
        ]
      }
    ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      assert_equal 45, @war.reload.our_score
      assert_equal 33, @war.their_score

      cached = Rails.cache.read(@faction.war_cache_key)
      assert_equal 45, cached[:our_score]
      assert_equal 33, cached[:their_score]
    end
  end

  test "ignores rankedwars entries for a different war" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @enemy_member ])
    TornApi::Faction::RankedWars.any_instance.stubs(:fetch).returns([
      {
        "id" => 9999,
        "factions" => [
          { "id" => 99999, "score" => 90 },
          { "id" => 88888, "score" => 10 }
        ]
      }
    ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      assert_equal 30, @war.reload.our_score
      assert_equal 20, @war.their_score
    end
  end

  test "keeps polling members when the score refresh fails" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @enemy_member ])
    TornApi::Faction::RankedWars.any_instance.stubs(:fetch).raises(TornApi::ApiError, "Torn hiccup")

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      assert cached[:members].key?(5555555)
      assert_equal 30, cached[:our_score]
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
    @faction.torn_api_key&.destroy!

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

  test "polls for scheduled wars" do
    # Create a scheduled war (starts in the future)
    @war.update!(ended_at: Time.current) # End the current war
    scheduled_war = @faction.ranked_wars.create!(
      torn_war_id: 2002,
      opponent_faction_id: 77777,
      opponent_faction_name: "Future Enemy",
      started_at: 2.days.from_now,
      target_score: 18000,
      our_score: 0,
      their_score: 0
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @enemy_member ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      assert_not_nil cached
      assert_equal 77777, cached[:enemy_faction_id]
      assert_equal "Future Enemy", cached[:enemy_faction_name]
    end
  end

  test "outbound traveler parses destination from new Torn travel format" do
    traveling_member = TornApi::Faction::Members::Member.new(
      6666666, "TravelingPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "Traveling from Torn to Switzerland", "", "Traveling", "blue", nil, "airliner",
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ traveling_member ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      status = cached[:members][6666666][:status]

      assert_equal "Traveling", status[:state]
      assert_equal "Switzerland", status[:destination]
      assert_equal false, status[:returning]
    end
  end

  test "returning traveler resolves origin country as destination in new Torn travel format" do
    returning_member = TornApi::Faction::Members::Member.new(
      6666666, "TravelingPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "Traveling from Switzerland to Torn", "", "Traveling", "blue", nil, "airliner",
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ returning_member ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      status = cached[:members][6666666][:status]

      assert_equal "Traveling", status[:state]
      assert_equal "Switzerland", status[:destination]
      assert_equal true, status[:returning]
    end
  end

  test "outbound traveler in legacy format still parses destination" do
    traveling_member = TornApi::Faction::Members::Member.new(
      6666666, "TravelingPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "Traveling to Switzerland", "", "Traveling", "blue", nil, "airliner",
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ traveling_member ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      status = cached[:members][6666666][:status]

      assert_equal "Switzerland", status[:destination]
      assert_equal false, status[:returning]
    end
  end

  test "returning traveler in legacy format still parses destination" do
    returning_member = TornApi::Faction::Members::Member.new(
      6666666, "TravelingPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "Returning to Torn from Switzerland", "", "Traveling", "green", nil, "airliner",
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ returning_member ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      status = cached[:members][6666666][:status]

      assert_equal "Switzerland", status[:destination]
      assert_equal true, status[:returning]
    end
  end

  test "abroad member includes description but no destination" do
    abroad_member = TornApi::Faction::Members::Member.new(
      6666666, "AbroadPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "In Switzerland", "", "Abroad", "blue", nil, nil,
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ abroad_member ])

    with_memory_cache do
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      status = cached[:members][6666666][:status]

      assert_equal "Abroad", status[:state]
      assert_equal "In Switzerland", status[:description]
      assert_nil status[:destination]
    end
  end

  test "first time travelers get travel_started_at stamped immediately" do
    traveling_member = TornApi::Faction::Members::Member.new(
      6666666, "TravelingPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "Traveling to Japan", "", "Traveling", "blue", nil, "airliner",
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ traveling_member ])

    with_memory_cache do
      freeze_time do
        WarPollingJob.perform_now(@faction.id)

        cached = Rails.cache.read(@faction.war_cache_key)
        member_data = cached[:members][6666666]

        assert_equal "Traveling", member_data[:status][:state]
        assert_equal "Japan", member_data[:status][:destination]
        assert_equal Time.current.iso8601, member_data[:status][:travel_started_at]
      end
    end
  end

  test "stamps travel_started_at when member transitions to traveling" do
    hospital_member = TornApi::Faction::Members::Member.new(
      6666666, "HospitalPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "In hospital for 30 minutes", "", "Hospital", "red", (Time.current + 30.minutes).to_i, nil,
      "Everyone", "Member", true, false, false, false
    )

    traveling_member = TornApi::Faction::Members::Member.new(
      6666666, "HospitalPlayer", 50, 30,
      "Online", 1708000000, "1 minute ago",
      "Traveling to Japan", "", "Traveling", "blue", nil, "airliner",
      "Everyone", "Member", true, false, false, false
    )

    with_memory_cache do
      # First poll — member is in hospital
      TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ hospital_member ])
      WarPollingJob.perform_now(@faction.id)

      cached = Rails.cache.read(@faction.war_cache_key)
      assert_equal "Hospital", cached[:members][6666666][:status][:state]

      # Second poll — member is now traveling (state transition)
      TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ traveling_member ])
      freeze_time do
        WarPollingJob.perform_now(@faction.id)

        cached = Rails.cache.read(@faction.war_cache_key)
        status = cached[:members][6666666][:status]

        assert_equal "Traveling", status[:state]
        assert_equal Time.current.iso8601, status[:travel_started_at]
      end
    end
  end

  test "carries forward travel_started_at for ongoing travelers" do
    traveling_member = TornApi::Faction::Members::Member.new(
      6666666, "TravelingPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "Traveling to Japan", "", "Traveling", "blue", nil, "airliner",
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ traveling_member ])

    with_memory_cache do
      freeze_time do
        WarPollingJob.perform_now(@faction.id)
        cached = Rails.cache.read(@faction.war_cache_key)
        departure_time = cached[:members][6666666][:status][:travel_started_at]
        assert_equal Time.current.iso8601, departure_time

        WarPollingJob.perform_now(@faction.id)
        cached = Rails.cache.read(@faction.war_cache_key)

        assert_equal departure_time, cached[:members][6666666][:status][:travel_started_at]
      end
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
