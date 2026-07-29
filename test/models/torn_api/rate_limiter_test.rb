require "test_helper"

class TornApi::RateLimiterTest < ActiveSupport::TestCase
  setup do
    freeze_time # budget windows are 60s wide; a boundary mid-test resets them
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
  end

  test "budget is half of torn's hard limit" do
    assert_equal 100, TornApi::RateLimiter::TORN_HARD_LIMIT
    assert_equal 50, TornApi::RateLimiter::REQUESTS_PER_MINUTE
  end

  test "allows requests up to the per-key budget" do
    assert_nothing_raised do
      50.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }
    end
  end

  test "rejects the request that exceeds the budget" do
    50.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }

    assert_raises(TornApi::RateLimitError) do
      TornApi::RateLimiter.acquire!("FACTION_KEY_123")
    end
  end

  test "budget resets after the window passes" do
    50.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }

    travel 61.seconds do
      assert_nothing_raised do
        TornApi::RateLimiter.acquire!("FACTION_KEY_123")
      end
    end
  end

  test "each key has an independent budget" do
    50.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }

    assert_nothing_raised do
      TornApi::RateLimiter.acquire!("OTHER_KEY_456")
    end
  end

  test "remaining reports the unused budget for a key" do
    assert_equal 50, TornApi::RateLimiter.remaining("FACTION_KEY_123")

    10.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }

    assert_equal 40, TornApi::RateLimiter.remaining("FACTION_KEY_123")
  end

  test "background work stops at 85% of the key budget" do
    assert_equal 42, TornApi::RateLimiter::BACKGROUND_REQUESTS_PER_MINUTE

    TornApi::RateLimiter.reserving_headroom_for_live_traffic do
      assert_nothing_raised { 42.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") } }
      assert_raises(TornApi::RateLimitError) { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }
    end
  end

  test "live traffic keeps the headroom a saturating background job leaves" do
    TornApi::RateLimiter.reserving_headroom_for_live_traffic do
      42.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }
      assert_raises(TornApi::RateLimitError) { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }
    end

    assert_nothing_raised { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }
  end

  test "background mode does not leak across the thread after the block" do
    TornApi::RateLimiter.reserving_headroom_for_live_traffic { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }

    assert_nothing_raised do
      49.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }
    end
  end

  test "background mode survives a nested block ending" do
    TornApi::RateLimiter.reserving_headroom_for_live_traffic do
      TornApi::RateLimiter.reserving_headroom_for_live_traffic { }

      42.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }
      assert_raises(TornApi::RateLimitError) { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }
    end
  end

  test "global budget is 300 requests per minute across all keys" do
    assert_equal 300, TornApi::RateLimiter::GLOBAL_REQUESTS_PER_MINUTE
  end

  test "the global budget trips even when no single key is over" do
    6.times do |i|
      50.times { TornApi::RateLimiter.acquire!("KEY_#{i}") }
    end

    assert_raises(TornApi::RateLimitError) do
      TornApi::RateLimiter.acquire!("FRESH_KEY")
    end
  end

  test "global budget resets after the window passes" do
    6.times do |i|
      50.times { TornApi::RateLimiter.acquire!("KEY_#{i}") }
    end

    travel 61.seconds do
      assert_nothing_raised do
        TornApi::RateLimiter.acquire!("FRESH_KEY")
      end
    end
  end
end
