require "test_helper"

class Factions::Leadership::SpyReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @faction.create_faction_setting!(torn_api_key: "FACTION_KEY_123", torn_api_access_type: "Limited Access")

    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction, subscription_expires_at: 1.month.from_now)
    @bert.update!(faction: @faction, subscription_expires_at: 1.month.from_now)

    @bram.update!(leadership_access: true)
  end

  test "requires authentication" do
    get faction_leadership_spy_reports_path(@faction)
    assert_redirected_to new_session_path
  end

  test "requires leadership access" do
    sign_in_as(@bert)
    get faction_leadership_spy_reports_path(@faction)
    assert_redirected_to faction_path(@faction)
  end

  test "shows page for leadership member" do
    sign_in_as(@bram)
    get faction_leadership_spy_reports_path(@faction)
    assert_response :success
    assert_select "a.back-link", "← Back to Leadership"
  end

  test "shows empty state when no reports" do
    sign_in_as(@bram)
    get faction_leadership_spy_reports_path(@faction)
    assert_response :success
    assert_select "p", "No spy reports imported yet."
  end

  test "shows table when reports exist" do
    @faction.spy_reports.create!(
      torn_id: 111, total: 1000,
      strength: 250, defense: 250, speed: 250, dexterity: 250,
      spied_at: 1.day.ago
    )

    sign_in_as(@bram)
    get faction_leadership_spy_reports_path(@faction)
    assert_response :success
  end

  test "redirects to setup when no api keys" do
    @faction.faction_setting.update!(torn_api_key: nil)
    sign_in_as(@bram)
    get faction_leadership_spy_reports_path(@faction)
    assert_redirected_to setup_faction_leadership_path(@faction)
  end
end
