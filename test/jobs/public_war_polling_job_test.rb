require "test_helper"

class PublicWarPollingJobTest < ActiveJob::TestCase
  setup do
    @lobby = public_war_lobbies(:open_lobby)

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
      Rails.cache.write(@lobby.api_key_cache_key, "test_api_key")

      PublicWarPollingJob.perform_now(@lobby.id)

      cached = Rails.cache.read(@lobby.war_cache_key)
      assert_not_nil cached
      assert_equal "Test Faction", cached[:faction_name]
      assert_equal "Enemy Faction", cached[:opponent_faction_name]
      assert cached[:members].key?(5555555)
      assert_not_nil cached[:cached_at]
    end
  end

  test "includes member status in cached data" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @enemy_member ])

    with_memory_cache do
      Rails.cache.write(@lobby.api_key_cache_key, "test_api_key")

      PublicWarPollingJob.perform_now(@lobby.id)

      cached = Rails.cache.read(@lobby.war_cache_key)
      member_data = cached[:members][5555555]
      assert_equal "Hospital", member_data[:status][:state]
    end
  end

  test "re-enqueues itself after completing" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @enemy_member ])

    with_memory_cache do
      Rails.cache.write(@lobby.api_key_cache_key, "test_api_key")

      assert_enqueued_with(job: PublicWarPollingJob, args: [ @lobby.id ]) do
        PublicWarPollingJob.perform_now(@lobby.id)
      end
    end
  end

  test "terminates lobby when API key is missing from cache" do
    with_memory_cache do
      # No API key in cache
      assert_difference "PublicWarLobby.count", -1 do
        PublicWarPollingJob.perform_now(@lobby.id)
      end
    end
  end

  test "terminates lobby on invalid API key" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "Invalid key")

    with_memory_cache do
      Rails.cache.write(@lobby.api_key_cache_key, "bad_key")

      assert_difference "PublicWarLobby.count", -1 do
        PublicWarPollingJob.perform_now(@lobby.id)
      end
    end
  end

  test "re-enqueues on standard error" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).raises(StandardError, "Something broke")

    with_memory_cache do
      Rails.cache.write(@lobby.api_key_cache_key, "test_api_key")

      assert_enqueued_with(job: PublicWarPollingJob, args: [ @lobby.id ]) do
        PublicWarPollingJob.perform_now(@lobby.id)
      end
    end
  end

  test "returns early for non-existent lobby" do
    assert_nothing_raised do
      PublicWarPollingJob.perform_now(0)
    end
  end

  # -- Travel data --

  test "outbound traveler includes destination" do
    traveling_member = TornApi::Faction::Members::Member.new(
      6666666, "TravelingPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "Traveling to Switzerland", "", "Traveling", "blue", nil, "airliner",
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ traveling_member ])

    with_memory_cache do
      Rails.cache.write(@lobby.api_key_cache_key, "test_api_key")

      PublicWarPollingJob.perform_now(@lobby.id)

      cached = Rails.cache.read(@lobby.war_cache_key)
      status = cached[:members][6666666][:status]

      assert_equal "Traveling", status[:state]
      assert_equal "Switzerland", status[:destination]
    end
  end

  test "returning traveler includes destination" do
    returning_member = TornApi::Faction::Members::Member.new(
      6666666, "TravelingPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "Returning to Torn from Switzerland", "", "Traveling", "green", nil, "airliner",
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ returning_member ])

    with_memory_cache do
      Rails.cache.write(@lobby.api_key_cache_key, "test_api_key")

      PublicWarPollingJob.perform_now(@lobby.id)

      cached = Rails.cache.read(@lobby.war_cache_key)
      status = cached[:members][6666666][:status]

      assert_equal "Traveling", status[:state]
      assert_equal "Switzerland", status[:destination]
    end
  end

  test "first time travelers have no travel_started_at" do
    traveling_member = TornApi::Faction::Members::Member.new(
      6666666, "TravelingPlayer", 50, 30,
      "Online", 1708000000, "5 minutes ago",
      "Traveling to Japan", "", "Traveling", "blue", nil, "airliner",
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ traveling_member ])

    with_memory_cache do
      Rails.cache.write(@lobby.api_key_cache_key, "test_api_key")

      PublicWarPollingJob.perform_now(@lobby.id)

      cached = Rails.cache.read(@lobby.war_cache_key)
      assert_nil cached[:members][6666666][:status][:travel_started_at]
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
      Rails.cache.write(@lobby.api_key_cache_key, "test_api_key")

      # First poll — member is in hospital
      TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ hospital_member ])
      PublicWarPollingJob.perform_now(@lobby.id)

      cached = Rails.cache.read(@lobby.war_cache_key)
      assert_equal "Hospital", cached[:members][6666666][:status][:state]

      # Second poll — member is now traveling (state transition)
      TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ traveling_member ])
      freeze_time do
        PublicWarPollingJob.perform_now(@lobby.id)

        cached = Rails.cache.read(@lobby.war_cache_key)
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
      Rails.cache.write(@lobby.api_key_cache_key, "test_api_key")

      # First poll — no travel_started_at
      PublicWarPollingJob.perform_now(@lobby.id)
      cached = Rails.cache.read(@lobby.war_cache_key)
      assert_nil cached[:members][6666666][:status][:travel_started_at]

      # Manually set travel_started_at to simulate departure detection
      departure_time = Time.current.iso8601
      cached[:members][6666666][:status][:travel_started_at] = departure_time
      Rails.cache.write(@lobby.war_cache_key, cached)

      # Second poll — should carry forward departure time
      PublicWarPollingJob.perform_now(@lobby.id)
      cached = Rails.cache.read(@lobby.war_cache_key)

      assert_equal departure_time, cached[:members][6666666][:status][:travel_started_at]
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
