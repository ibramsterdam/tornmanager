require "test_helper"

class Factions::Leadership::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @faction.create_faction_setting!
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")

    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction, subscription_expires_at: 1.month.from_now)
    @bert.update!(faction: @faction, subscription_expires_at: 1.month.from_now)

    @bram.update!(leadership_access: true)
  end

  test "requires authentication" do
    get faction_leadership_settings_path(@faction)
    assert_redirected_to new_session_path
  end

  test "requires leadership access" do
    sign_in_as(@bert)
    get faction_leadership_settings_path(@faction)
    assert_redirected_to faction_path(@faction)
  end

  test "shows page for leadership member" do
    sign_in_as(@bram)
    get faction_leadership_settings_path(@faction)
    assert_response :success
    assert_select "a.back-link", "← Back to Leadership"
  end

  test "shows api configuration card" do
    sign_in_as(@bram)
    get faction_leadership_settings_path(@faction)
    assert_response :success
    assert_select "h3", "API Configuration"
  end

  test "shows leadership access card" do
    sign_in_as(@bram)
    get faction_leadership_settings_path(@faction)
    assert_response :success
    assert_select "h3", "Leadership Access"
  end

  test "redirects to setup when no api keys" do
    @faction.torn_api_key&.destroy!
    sign_in_as(@bram)
    get faction_leadership_settings_path(@faction)
    assert_redirected_to faction_leadership_setup_path(@faction)
  end
end
