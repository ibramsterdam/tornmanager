require "test_helper"

class TornApi::User::PersonalStatsTest < ActiveSupport::TestCase
  test "an empty personalstats payload raises TransientError so jobs retry" do
    # Torn intermittently returns {"personalstats" => nil} around the nightly
    # stats-cache rebuild (the 04:50 errors). That's retryable, not fatal.
    stats = TornApi::User::PersonalStats.new("FACTION_KEY_123", 12345)
    stats.stubs(:get).returns({ "personalstats" => nil })

    assert_raises(TornApi::TransientError) { stats.fetch }
  end

  test "a populated personalstats payload parses normally" do
    stats = TornApi::User::PersonalStats.new(
      "FACTION_KEY_123", 12345,
      stat_batch: { "xantaken" => :drugs_xanax }
    )
    stats.stubs(:get).returns(
      { "personalstats" => [ { "name" => "xantaken", "value" => 42, "timestamp" => 1_750_000_000 } ] }
    )

    result = stats.fetch
    assert_equal 42, result[:drugs_xanax]
  end
end
