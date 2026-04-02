require "test_helper"

class Recon::TornApi::PersonalStatsTest < ActiveSupport::TestCase
  setup do
    @api_key = "test_key"
    @player_id = 123456
    @timestamp = Date.new(2026, 3, 24).end_of_day.to_i
  end

  test "fetches specific stats with timestamp" do
    api_response = {
      "personalstats" => [
        { "name" => "xantaken", "value" => 500, "timestamp" => @timestamp },
        { "name" => "energydrinkused", "value" => 100, "timestamp" => @timestamp }
      ]
    }

    stats = %w[xantaken energydrinkused]
    service = Recon::TornApi::PersonalStats.new(@api_key, @player_id, stats: stats, timestamp: @timestamp)
    service.expects(:get).with("v2/user/#{@player_id}/personalstats", { stat: "xantaken,energydrinkused", timestamp: @timestamp }).returns(api_response)

    result = service.fetch
    assert_equal 500, result["xantaken"]
    assert_equal 100, result["energydrinkused"]
  end

  test "returns empty hash when personalstats is empty" do
    stats = %w[xantaken]
    service = Recon::TornApi::PersonalStats.new(@api_key, @player_id, stats: stats, timestamp: @timestamp)
    service.expects(:get).returns({ "personalstats" => [] })

    result = service.fetch
    assert_equal({}, result)
  end
end
