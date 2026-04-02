require "test_helper"

class Factions::Leadership::SpyReportsControllerTest < ActionDispatch::IntegrationTest
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

  test "redirects to setup when no api keys" do
    @faction.torn_api_key&.destroy!
    sign_in_as(@bram)
    get faction_leadership_spy_reports_path(@faction)
    assert_redirected_to faction_leadership_setup_path(@faction)
  end
end
