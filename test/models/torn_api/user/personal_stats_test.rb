require "test_helper"

class TornApi::User::PersonalStatsTest < ActiveSupport::TestCase
  test "an empty personalstats payload raises NoDataError" do
    # Torn returns {"personalstats" => nil} both transiently (nightly cache
    # rebuild) and permanently (no data exists for that player/date). Jobs
    # decide which: daily fetches retry it, historical backfills tombstone it.
    stats = TornApi::User::PersonalStats.new("FACTION_KEY_123", 12345)
    stats.stubs(:get).returns({ "personalstats" => nil })

    assert_raises(TornApi::NoDataError) { stats.fetch }
  end

  test "NoDataError is still a TransientError so daily fetches retry it" do
    assert TornApi::NoDataError < TornApi::TransientError
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
