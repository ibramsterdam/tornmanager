require "test_helper"

# The budget must be enforced at the client, before the HTTP request goes
# out: a rejected request that still reaches Torn counts toward the real
# 100/minute hard limit, which is exactly what we're trying to protect.
class TornApi::BaseBudgetTest < ActiveSupport::TestCase
  setup do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    @base = TornApi::Base.new("FACTION_KEY_123")
  end

  test "get consumes budget from the key's rate limiter" do
    stub_success

    assert_difference -> { 50 - TornApi::RateLimiter.remaining("FACTION_KEY_123") }, 2 do
      @base.get("v2/user/12345/personalstats")
      @base.get("v2/user/12345/personalstats")
    end
  end

  test "get raises RateLimitError without hitting the network when budget is spent" do
    50.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }
    @base.expects(:perform_request).never

    assert_raises(TornApi::RateLimitError) do
      @base.get("v2/user/12345/personalstats")
    end
  end

  test "an exhausted key does not block requests on other keys" do
    50.times { TornApi::RateLimiter.acquire!("FACTION_KEY_123") }

    other = TornApi::Base.new("OTHER_KEY_456")
    other.stubs(:perform_request).returns(stub(code: "200", body: { "ok" => 1 }.to_json))

    assert_equal 1, other.get("v2/user/12345/personalstats")["ok"]
  end

  private

  def stub_success
    @base.stubs(:perform_request).returns(stub(code: "200", body: { "ok" => 1 }.to_json))
  end
end
