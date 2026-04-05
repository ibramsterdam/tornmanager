require "test_helper"

class Factions::Leadership::WarReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @faction.create_faction_setting!
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY", access_type: "Limited Access", faction_access: true)

    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction, subscription_expires_at: 1.month.from_now, leadership_access: true)
    @bert.update!(faction: @faction, subscription_expires_at: 1.month.from_now)

    @war = @faction.ranked_wars.create!(
      torn_war_id: 1001, opponent_faction_id: 88888, opponent_faction_name: "Enemy",
      started_at: 1.week.ago, ended_at: 3.days.ago, target_score: 100,
      our_score: 100, their_score: 50, winner_faction_id: @faction.torn_id,
      our_attacks: 5, their_attacks: 3
    )
  end

  # -- Access control --

  test "requires authentication" do
    get faction_leadership_war_reports_path(@faction)
    assert_redirected_to new_session_path
  end

  test "requires leadership access" do
    sign_in_as(@bert)
    get faction_leadership_war_reports_path(@faction)
    assert_redirected_to faction_path(@faction)
  end

  test "redirects to setup when no api keys" do
    @faction.torn_api_key&.destroy!
    sign_in_as(@bram)
    get faction_leadership_war_reports_path(@faction)
    assert_redirected_to faction_leadership_setup_path(@faction)
  end

  # -- Show --

  test "shows page with war sidebar" do
    sign_in_as(@bram)
    get faction_leadership_war_reports_path(@faction)
    assert_response :success
    assert_select ".war-reports-left"
    assert_select "a.back-link"
  end

  test "selects first war by default" do
    sign_in_as(@bram)
    get faction_leadership_war_reports_path(@faction)
    assert_response :success
    assert_select ".war-reports-middle h2", /Enemy/
  end

  test "selects war via query param" do
    other_war = @faction.ranked_wars.create!(
      torn_war_id: 1002, opponent_faction_id: 77777, opponent_faction_name: "Other Enemy",
      started_at: 2.weeks.ago, ended_at: 1.week.ago, target_score: 100,
      our_score: 50, their_score: 100, winner_faction_id: 77777
    )

    sign_in_as(@bram)
    get faction_leadership_war_reports_path(@faction, war: 1002)
    assert_response :success
    assert_select ".war-reports-middle h2", /Other Enemy/
  end

  test "always shows table and payout form" do
    sign_in_as(@bram)
    get faction_leadership_war_reports_path(@faction)
    assert_response :success
    assert_select "table"
    assert_select ".war-reports-payout-form"
  end

  test "shows fetch button with yellow dot when incomplete" do
    sign_in_as(@bram)
    get faction_leadership_war_reports_path(@faction)
    assert_response :success
    assert_select ".pulse-dot-yellow"
    assert_select "button", text: /Fetch/
  end

  test "shows fetch button with green dot when complete" do
    @war.update!(our_attacks: 0)

    sign_in_as(@bram)
    get faction_leadership_war_reports_path(@faction)
    assert_response :success
    assert_select ".pulse-dot-green"
  end

  test "shows empty state when no completed wars" do
    @war.destroy!
    sign_in_as(@bram)
    get faction_leadership_war_reports_path(@faction)
    assert_response :success
    assert_select ".war-reports-middle", /No completed wars/
  end

  # -- Fetch attacks --

  test "fetch_attacks runs job inline and redirects" do
    FetchWarAttacksJob.any_instance.stubs(:perform)
    RankedWar.any_instance.stubs(:calculate_reward_value!)

    sign_in_as(@bram)
    post fetch_attacks_faction_leadership_war_reports_path(@faction, war: @war.torn_war_id)

    assert_redirected_to faction_leadership_war_reports_path(@faction, war: @war.torn_war_id)
    assert_match /Fetched/, flash[:notice]
  end

  test "fetch_attacks requires leadership access" do
    sign_in_as(@bert)
    post fetch_attacks_faction_leadership_war_reports_path(@faction, war: @war.torn_war_id)
    assert_redirected_to faction_path(@faction)
  end

  test "fetch_attacks requires faction_access on api key" do
    @faction.torn_api_key.update!(faction_access: false)

    sign_in_as(@bram)
    post fetch_attacks_faction_leadership_war_reports_path(@faction, war: @war.torn_war_id)

    assert_redirected_to faction_leadership_war_reports_path(@faction, war: @war.torn_war_id)
    assert_match /faction API access/, flash[:alert]
  end

  private

  def create_attack(attrs = {})
    @war.ranked_war_attacks.create!({
      torn_attack_id: attrs[:torn_attack_id] || 1,
      attacker_id: 111, attacker_name: "Attacker",
      attacker_faction_id: attrs[:attacker_faction_id] || @faction.torn_id,
      defender_id: 222, defender_name: "Defender",
      defender_faction_id: 88888,
      started: 1.week.ago.to_i, ended: 1.week.ago.to_i + 10,
      result: "Attacked", respect_gain: 5.0,
      fair_fight: 3, war: 2, warlord: 1, overseas: 1
    }.merge(attrs.except(:attacker_faction_id, :torn_attack_id)))
  end
end
