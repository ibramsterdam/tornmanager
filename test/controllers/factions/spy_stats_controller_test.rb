require "test_helper"

class Factions::SpyStatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999,
      name: "Test Faction",
      track_stats: true,
      xanax_target: 2.5
    )
    @bram = users(:bram)
    @bram.update!(faction: @faction)
    sign_in_as(@bram)
  end

  test "shows spy stats when both keys are configured" do
    @faction.create_faction_setting!(
      torn_api_key: "faction_key_123",
      torn_api_access_type: "Limited Access",
      tornstats_api_key: "ts_key_456"
    )

    get faction_spy_stats_path(@faction)
    assert_response :success
  end

  test "redirects to settings when torn api key is missing" do
    @faction.create_faction_setting!(tornstats_api_key: "ts_key_456")

    get faction_spy_stats_path(@faction)
    assert_redirected_to faction_settings_path(@faction)
    assert_match /API keys must be configured/, flash[:alert]
  end

  test "redirects to settings when tornstats key is missing" do
    @faction.create_faction_setting!(
      torn_api_key: "faction_key_123",
      torn_api_access_type: "Limited Access"
    )

    get faction_spy_stats_path(@faction)
    assert_redirected_to faction_settings_path(@faction)
    assert_match /API keys must be configured/, flash[:alert]
  end

  test "redirects to settings when no faction setting exists" do
    get faction_spy_stats_path(@faction)
    assert_redirected_to faction_settings_path(@faction)
    assert_match /API keys must be configured/, flash[:alert]
  end
end
