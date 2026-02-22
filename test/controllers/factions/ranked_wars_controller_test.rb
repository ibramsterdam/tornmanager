require "test_helper"

class Factions::RankedWarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test Faction", track_stats: true, xanax_target: 2.5)
    @bram = users(:bram)
    @bram.update!(faction: @faction)
    sign_in_as(@bram)
  end

  test "sync redirects to settings when no faction torn api key configured" do
    post sync_faction_ranked_wars_path(@faction)

    assert_redirected_to faction_settings_path(@faction)
    assert_match /Torn API key must be configured/, flash[:alert]
  end

  test "sync uses the faction configured torn api key" do
    @faction.create_faction_setting!(
      torn_api_key: "faction_limited_key",
      torn_api_access_type: "Limited Access"
    )

    wars_api = mock
    wars_api.stubs(:fetch).returns([])
    TornApi::Faction::RankedWars.expects(:new).with("faction_limited_key", @faction.torn_id).returns(wars_api)

    post sync_faction_ranked_wars_path(@faction)

    assert_redirected_to faction_ranked_wars_path(@faction)
    assert_match /Synced 0 ranked wars/, flash[:notice]
  end
end
