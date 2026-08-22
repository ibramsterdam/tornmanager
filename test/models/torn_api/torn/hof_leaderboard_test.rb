require "test_helper"

class TornApi::Torn::HofLeaderboardTest < ActiveSupport::TestCase
  test "fetches a page of the working stats leaderboard" do
    response = {
      "hof" => [
        { "id" => 111, "username" => "Top", "level" => 90, "value" => 565457, "last_action" => 1755800000 },
        { "id" => 222, "username" => "Next", "level" => 85, "value" => 483000, "last_action" => 1755700000 }
      ]
    }
    service = TornApi::Torn::HofLeaderboard.new("test_key", offset: 200)
    service.expects(:get)
      .with("v2/torn/hof", { cat: "workstats", limit: 100, offset: 200, comment: "tmrecruiter" })
      .returns(response)

    rows = service.fetch

    assert_equal 2, rows.size
    assert_equal 111, rows.first.torn_id
    assert_equal "Top", rows.first.name
    assert_equal 565457, rows.first.value
    assert_equal 1755700000, rows.last.last_action
  end

  test "returns an empty array past the end of the leaderboard" do
    service = TornApi::Torn::HofLeaderboard.new("test_key", offset: 999900)
    service.expects(:get).returns({ "hof" => [] })

    assert_empty service.fetch
  end
end
