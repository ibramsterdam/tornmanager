require "test_helper"

class TornApi::Torn::EliminationTest < ActiveSupport::TestCase
  test "fetches all elimination teams" do
    response = {
      "elimination" => [
        {
          "id" => 80, "name" => "Conspiracy Theorists", "participants" => 2027,
          "position" => 3, "score" => 1298, "lives" => 48, "wins" => 7900,
          "losses" => 7500, "eliminated" => false, "eliminated_timestamp" => nil
        },
        {
          "id" => 82, "name" => "Gold Dust", "participants" => 2027,
          "position" => 12, "score" => 0, "lives" => 0, "wins" => 4100,
          "losses" => 6200, "eliminated" => true, "eliminated_timestamp" => 1757685600
        }
      ]
    }
    service = TornApi::Torn::Elimination.new("test_key")
    service.expects(:get).with("v2/torn/elimination").returns(response)

    teams = service.fetch

    assert_equal 2, teams.size
    assert_equal 80, teams.first.torn_id
    assert_equal "Conspiracy Theorists", teams.first.name
    assert_equal 1298, teams.first.tickets
    assert_equal 48, teams.first.lives
    assert_not teams.first.eliminated
    assert teams.last.eliminated
    assert_equal 1757685600, teams.last.eliminated_at
  end

  test "raises when no elimination data is returned" do
    service = TornApi::Torn::Elimination.new("test_key")
    service.expects(:get).returns({ "elimination" => [] })

    assert_raises(TornApi::ApiError) { service.fetch }
  end
end
