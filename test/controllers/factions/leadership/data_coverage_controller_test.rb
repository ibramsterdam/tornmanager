require "test_helper"

class Factions::Leadership::DataCoverageControllerTest < ActionDispatch::IntegrationTest
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

    @faction.faction_whitelists.create!(user: @bram)
  end

  test "requires authentication" do
    get faction_leadership_data_coverage_path(@faction)
    assert_redirected_to new_session_path
  end

  test "requires whitelist access" do
    sign_in_as(@bert)
    get faction_leadership_data_coverage_path(@faction)
    assert_redirected_to faction_path(@faction)
  end

  test "shows page for whitelisted member" do
    sign_in_as(@bram)
    get faction_leadership_data_coverage_path(@faction)
    assert_response :success
    assert_select "a.back-link", "← Back to Leadership"
  end

  test "shows member coverage table" do
    sign_in_as(@bram)
    get faction_leadership_data_coverage_path(@faction)
    assert_response :success
    assert_select "th", "Member"
    assert_select "th", "Coverage"
    assert_select "th", "Days Missing"
  end

  test "shows coverage stats for members with snapshots" do
    start_date = PersonalStatSnapshot.tracking_start_date
    (start_date..PersonalStatSnapshot.tracking_end_date).each do |date|
      PersonalStatSnapshot.create!(user: @bram, date: date, timestamp: date.to_time.to_i)
    end

    sign_in_as(@bram)
    get faction_leadership_data_coverage_path(@faction)
    assert_response :success
    assert_select "span.stat-compliant", "100.0%"
  end

  test "redirects to setup when no api keys" do
    @faction.faction_setting.update!(torn_api_key: nil)
    sign_in_as(@bram)
    get faction_leadership_data_coverage_path(@faction)
    assert_redirected_to setup_faction_leadership_path(@faction)
  end
end
