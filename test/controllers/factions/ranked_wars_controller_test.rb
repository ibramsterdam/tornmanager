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

  test "index updates ongoing war to finished when api returns end timestamp" do
    @faction.create_faction_setting!(
      torn_api_key: "faction_limited_key",
      torn_api_access_type: "Limited Access"
    )

    # Create an ongoing war in the database
    ongoing_war = @faction.ranked_wars.create!(
      torn_war_id: 37405,
      opponent_faction_id: 35507,
      opponent_faction_name: "The Nest",
      started_at: 2.days.ago,
      ended_at: nil,
      target_score: 12600,
      our_score: 18521,
      their_score: 5769,
      winner_faction_id: nil
    )

    assert ongoing_war.ongoing?, "War should be ongoing before refresh"

    # API returns the war as finished
    finished_war_data = {
      "id" => 37405,
      "start" => 2.days.ago.to_i,
      "end" => 1.hour.ago.to_i,
      "target" => 12600,
      "winner" => @faction.torn_id,
      "factions" => [
        { "id" => @faction.torn_id, "name" => @faction.name, "score" => 18521 },
        { "id" => 35507, "name" => "The Nest", "score" => 5769 }
      ]
    }

    # Also a scheduled future war (most recent)
    scheduled_war_data = {
      "id" => 37896,
      "start" => 2.days.from_now.to_i,
      "end" => 0,
      "target" => 18000,
      "winner" => nil,
      "factions" => [
        { "id" => @faction.torn_id, "name" => @faction.name, "score" => 0 },
        { "id" => 11747, "name" => "Natural Selection II", "score" => 0 }
      ]
    }

    wars_api = mock
    wars_api.stubs(:fetch).returns([ scheduled_war_data, finished_war_data ])
    TornApi::Faction::RankedWars.stubs(:new).returns(wars_api)

    get faction_ranked_wars_path(@faction)

    ongoing_war.reload
    assert ongoing_war.completed?, "War should be completed after refresh"
    assert_equal @faction.torn_id, ongoing_war.winner_faction_id
    assert ongoing_war.won?, "War should be marked as won"
  end

  test "show renders live dashboard with polling for scheduled war" do
    @faction.create_faction_setting!(
      torn_api_key: "faction_limited_key",
      torn_api_access_type: "Limited Access"
    )

    scheduled_war = @faction.ranked_wars.create!(
      torn_war_id: 37896,
      opponent_faction_id: 11747,
      opponent_faction_name: "Natural Selection II",
      started_at: 2.days.from_now,
      ended_at: nil,
      target_score: 18000,
      our_score: 0,
      their_score: 0
    )

    # Stub ranked wars API for refresh
    wars_api = mock
    wars_api.stubs(:fetch).returns([])
    TornApi::Faction::RankedWars.stubs(:new).returns(wars_api)

    # Expect war polling to be started
    assert_enqueued_with(job: WarPollingJob) do
      get faction_ranked_war_path(@faction, scheduled_war)
    end

    assert_response :success
    # Should render the live dashboard partial
    assert_select "[data-controller='war-dashboard']"
  end
end
