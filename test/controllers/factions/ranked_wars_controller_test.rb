require "test_helper"

class Factions::RankedWarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test Faction", track_stats: true, xanax_target: 2.5)
    @bram = users(:bram)
    @bram.update!(faction: @faction)
    sign_in_as(@bram)
  end

  test "index does not refresh wars when no faction torn api key configured" do
    TornApi::Faction::RankedWars.expects(:new).never

    get faction_ranked_wars_path(@faction)

    assert_response :success
  end

  test "index refreshes latest war using faction api key" do
    @faction.create_faction_setting!(
      torn_api_key: "faction_limited_key",
      torn_api_access_type: "Limited Access"
    )

    wars_api = mock
    wars_api.stubs(:fetch).returns([])
    TornApi::Faction::RankedWars.expects(:new).with("faction_limited_key", @faction.torn_id).returns(wars_api)

    get faction_ranked_wars_path(@faction)

    assert_response :success
  end

  test "index creates new war from api response" do
    @faction.create_faction_setting!(
      torn_api_key: "faction_limited_key",
      torn_api_access_type: "Limited Access"
    )

    war_data = {
      "id" => 12345,
      "start" => 1.day.ago.to_i,
      "end" => 0,
      "target" => 100,
      "winner" => nil,
      "factions" => [
        { "id" => @faction.torn_id, "name" => @faction.name, "score" => 50 },
        { "id" => 88888, "name" => "Enemy Faction", "score" => 30 }
      ]
    }

    wars_api = mock
    wars_api.stubs(:fetch).returns([ war_data ])
    TornApi::Faction::RankedWars.stubs(:new).returns(wars_api)

    assert_difference -> { @faction.ranked_wars.count }, 1 do
      get faction_ranked_wars_path(@faction)
    end

    war = @faction.ranked_wars.find_by(torn_war_id: 12345)
    assert_equal 88888, war.opponent_faction_id
    assert_equal "Enemy Faction", war.opponent_faction_name
    assert_equal 50, war.our_score
    assert_equal 30, war.their_score
  end
end
