require "test_helper"

class Factions::WarHistoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999,
      name: "Test Faction",
      xanax_target: 2.5,
      energy_refill_target: 1.0,
      nerve_refill_target: 1.0,
      setup_completed: true
    )
    @bram = users(:bram)
    @bert = users(:bert)
    @kaneki = users(:kaneki)
    @bram.update!(faction: @faction)
    @bert.update!(faction: @faction)
    grant_subscription(@faction, expires_at: 1.month.from_now)

    @won_war = @faction.ranked_wars.create!(
      torn_war_id: 1001, opponent_faction_id: 88888, opponent_faction_name: "Enemy A",
      started_at: Date.new(2026, 2, 15).to_time, ended_at: Date.new(2026, 2, 16).to_time,
      target_score: 100, our_score: 100, their_score: 50,
      winner_faction_id: @faction.torn_id
    )
    @lost_war = @faction.ranked_wars.create!(
      torn_war_id: 1002, opponent_faction_id: 77777, opponent_faction_name: "Enemy B",
      started_at: Date.new(2026, 2, 10).to_time, ended_at: Date.new(2026, 2, 11).to_time,
      target_score: 100, our_score: 50, their_score: 100,
      winner_faction_id: 77777
    )
  end

  test "faction member can access war history" do
    sign_in_as(@bert)
    get faction_war_history_path(@faction)
    assert_response :success
  end

  test "admin can access war history" do
    sign_in_as(@bram)
    get faction_war_history_path(@faction)
    assert_response :success
  end

  test "non-member is redirected" do
    @kaneki.update!(faction: nil)
    sign_in_as(@kaneki)
    get faction_war_history_path(@faction)
    assert_redirected_to root_path
  end

  test "unauthenticated user is redirected to login" do
    get faction_war_history_path(@faction)
    assert_redirected_to new_session_path
  end

  test "displays war history table with wars" do
    sign_in_as(@bert)
    get faction_war_history_path(@faction)
    assert_select ".war-history-content .table-container", minimum: 1
    assert_select "table thead th", text: "Opponent"
  end

  test "displays member performance table" do
    @won_war.update!(our_members: [
      { "id" => @bert.torn_id, "name" => @bert.name, "attacks" => 15, "score" => 45.5 }
    ])

    sign_in_as(@bert)
    get faction_war_history_path(@faction)
    assert_select "table thead th", text: "Total Attacks"
  end

  test "shows win and loss counts for current year" do
    sign_in_as(@bert)
    get faction_war_history_path(@faction)
    assert_response :success
    assert_select ".stat-wins", "1"
    assert_select ".stat-losses", "1"
  end

  test "back link points to faction dashboard" do
    sign_in_as(@bert)
    get faction_war_history_path(@faction)
    assert_select "a.back-link[href=?]", faction_path(@faction)
  end
end
