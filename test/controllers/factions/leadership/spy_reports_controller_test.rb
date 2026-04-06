require "test_helper"

class Factions::Leadership::SpyReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @faction.create_faction_setting!
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")
    ApiKey::Tornstats.create!(faction: @faction, key: "TS_KEY_123")

    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction, leadership_access: true)
    @bert.update!(faction: @faction)
    grant_subscription(@faction, expires_at: 1.month.from_now)
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

  test "redirects to leadership with flash when no tornstats key" do
    @faction.tornstats_api_key&.destroy!
    sign_in_as(@bram)
    get faction_leadership_spy_reports_path(@faction)
    assert_redirected_to faction_leadership_path(@faction)
    assert_match /TornStats API key/, flash[:alert]
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

  # -- Update --

  test "update changes stat value and recalculates total" do
    report = @faction.spy_reports.create!(
      torn_id: 111, strength: 100, defense: 200, speed: 300, dexterity: 400, total: 1000
    )

    sign_in_as(@bram)
    patch update_report_faction_leadership_spy_reports_path(@faction, report.id),
      params: { spy_report: { strength: 500 } },
      as: :json

    assert_response :success
    report.reload
    assert_equal 500, report.strength
    assert_equal 1400, report.total
  end

  test "update returns error for invalid data" do
    report = @faction.spy_reports.create!(
      torn_id: 111, strength: 100, defense: 200, speed: 300, dexterity: 400, total: 1000
    )

    sign_in_as(@bram)
    patch update_report_faction_leadership_spy_reports_path(@faction, report.id),
      params: { spy_report: { strength: "not_a_number" } },
      as: :json

    assert_response :success
    report.reload
    assert_equal 0, report.strength # "not_a_number".to_i = 0
  end

  test "update requires leadership access" do
    report = @faction.spy_reports.create!(
      torn_id: 111, strength: 100, defense: 200, speed: 300, dexterity: 400, total: 1000
    )

    sign_in_as(@bert)
    patch update_report_faction_leadership_spy_reports_path(@faction, report.id),
      params: { spy_report: { strength: 500 } },
      as: :json

    assert_redirected_to faction_path(@faction)
  end

  test "update cannot modify reports from another faction" do
    other_faction = Faction.create!(torn_id: 88888, name: "Other", xanax_target: 2.5)
    other_report = other_faction.spy_reports.create!(
      torn_id: 222, strength: 100, defense: 100, speed: 100, dexterity: 100, total: 400
    )

    sign_in_as(@bram)
    patch update_report_faction_leadership_spy_reports_path(@faction, other_report.id),
      params: { spy_report: { strength: 999 } },
      as: :json

    assert_response :not_found
    assert_equal 100, other_report.reload.strength
  end

  # -- Destroy --

  test "destroy deletes the spy report" do
    report = @faction.spy_reports.create!(
      torn_id: 111, strength: 100, defense: 200, speed: 300, dexterity: 400, total: 1000
    )

    sign_in_as(@bram)

    assert_difference "@faction.spy_reports.count", -1 do
      delete destroy_report_faction_leadership_spy_reports_path(@faction, report.id)
    end

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /deleted/, flash[:notice]
  end

  test "destroy requires leadership access" do
    report = @faction.spy_reports.create!(
      torn_id: 111, strength: 100, defense: 200, speed: 300, dexterity: 400, total: 1000
    )

    sign_in_as(@bert)
    delete destroy_report_faction_leadership_spy_reports_path(@faction, report.id)

    assert_redirected_to faction_path(@faction)
    assert SpyReport.exists?(report.id)
  end

  test "destroy cannot delete reports from another faction" do
    other_faction = Faction.create!(torn_id: 88888, name: "Other", xanax_target: 2.5)
    other_report = other_faction.spy_reports.create!(
      torn_id: 222, strength: 100, defense: 100, speed: 100, dexterity: 100, total: 400
    )

    sign_in_as(@bram)
    delete destroy_report_faction_leadership_spy_reports_path(@faction, other_report.id)

    assert_response :not_found
    assert SpyReport.exists?(other_report.id)
  end

  # -- Show: current enemy button --

  test "show displays fetch enemy button when ongoing war exists" do
    create_ongoing_war

    sign_in_as(@bram)
    get faction_leadership_spy_reports_path(@faction)
    assert_response :success
    assert_select "button", text: /Sport Club/
  end

  test "show displays fetch enemy button when scheduled war exists" do
    @faction.ranked_wars.create!(
      torn_war_id: 2001, opponent_faction_id: 77777, opponent_faction_name: "Future Enemy",
      started_at: 1.day.from_now, ended_at: nil, target_score: 100,
      our_score: 0, their_score: 0
    )

    sign_in_as(@bram)
    get faction_leadership_spy_reports_path(@faction)
    assert_response :success
    assert_select "button", text: /Future Enemy/
  end

  test "show does not display fetch enemy button when no ongoing war" do
    sign_in_as(@bram)
    get faction_leadership_spy_reports_path(@faction)
    assert_response :success
    assert_select "button[data-turbo-submits-with]", count: 0
  end

  # -- Fetch enemy --

  test "fetch_enemy imports spy data for current war opponent" do
    create_ongoing_war

    spy_data = [
      TornStatsApi::SpyFaction::SpyData.new(
        torn_id: 111, name: "Enemy1", level: 50,
        strength: 1000, defense: 2000, speed: 3000, dexterity: 4000,
        total: 10000, spied_at: 1.day.ago
      )
    ]
    TornStatsApi::SpyFaction.any_instance.stubs(:fetch).returns(spy_data)

    sign_in_as(@bram)

    assert_difference "@faction.spy_reports.count", 1 do
      post fetch_enemy_faction_leadership_spy_reports_path(@faction)
    end

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /imported 1/, flash[:notice]
  end

  test "fetch_enemy requires tornstats api key" do
    create_ongoing_war
    @faction.tornstats_api_key&.destroy!

    sign_in_as(@bram)
    post fetch_enemy_faction_leadership_spy_reports_path(@faction)

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /TornStats API key/, flash[:alert]
  end

  test "fetch_enemy requires ongoing war" do
    sign_in_as(@bram)
    post fetch_enemy_faction_leadership_spy_reports_path(@faction)

    assert_redirected_to faction_leadership_spy_reports_path(@faction)
    assert_match /No active war/, flash[:alert]
  end

  test "fetch_enemy requires leadership access" do
    create_ongoing_war

    sign_in_as(@bert)
    post fetch_enemy_faction_leadership_spy_reports_path(@faction)
    assert_redirected_to faction_path(@faction)
  end

  test "redirects to setup when no api keys" do
    @faction.torn_api_key&.destroy!
    sign_in_as(@bram)
    get faction_leadership_spy_reports_path(@faction)
    assert_redirected_to faction_leadership_setup_path(@faction)
  end

  private

  def create_ongoing_war
    @faction.ranked_wars.create!(
      torn_war_id: 2001, opponent_faction_id: 99937, opponent_faction_name: "Sport Club",
      started_at: 1.hour.ago, ended_at: nil, target_score: 18000,
      our_score: 0, their_score: 0
    )
  end
end
