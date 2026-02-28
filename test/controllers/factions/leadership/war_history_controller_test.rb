require "test_helper"

class Factions::Leadership::WarHistoryControllerTest < ActionDispatch::IntegrationTest
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
    get faction_leadership_war_history_path(@faction)
    assert_redirected_to new_session_path
  end

  test "requires leadership access" do
    sign_in_as(@bert)
    get faction_leadership_war_history_path(@faction)
    assert_redirected_to faction_path(@faction)
  end

  test "shows page for leadership member" do
    sign_in_as(@bram)
    get faction_leadership_war_history_path(@faction)
    assert_response :success
    assert_select "a.back-link", "← Back to Leadership"
  end

  test "shows wars table" do
    @faction.ranked_wars.create!(
      torn_war_id: 1001, opponent_faction_id: 88888, opponent_faction_name: "Enemy",
      started_at: 1.week.ago, ended_at: 3.days.ago, target_score: 100,
      our_score: 100, their_score: 50, winner_faction_id: @faction.torn_id
    )

    sign_in_as(@bram)
    get faction_leadership_war_history_path(@faction)
    assert_response :success
  end

  test "redirects to setup when no api keys" do
    @faction.faction_setting.update!(torn_api_key: nil)
    sign_in_as(@bram)
    get faction_leadership_war_history_path(@faction)
    assert_redirected_to faction_leadership_setup_path(@faction)
  end
end
