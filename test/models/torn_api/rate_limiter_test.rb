require "test_helper"

# Torn enforces 100 requests/minute per player across all their keys, and
# exceeding it (or spamming invalid keys) risks temporary IP bans. We
# self-impose HALF the hard limit per key, leaving headroom for the key
# owner's own usage (YATA, Torn PDA, browsing) that we can't see.
class TornApi::RateLimiterTest < ActiveSupport::TestCase
  setup do
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
    freeze_time do
      50.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }
    end

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

  # The per-key budget alone lets 30 keys sum to ~1500/min from one server IP.
  # Torn documents no aggregate limit, but error code 8 ("IP blocked for
  # abuse") exists — so the aggregate ceiling must be an explicit budget, not
  # an accident of the worker thread count.

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
    freeze_time do
      6.times do |i|
        50.times { TornApi::RateLimiter.acquire!("KEY_#{i}") }
      end
    end

    travel 61.seconds do
      assert_nothing_raised do
        TornApi::RateLimiter.acquire!("FRESH_KEY")
      end
    end
  end
end
