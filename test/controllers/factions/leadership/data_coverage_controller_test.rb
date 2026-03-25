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

    @bram.update!(leadership_access: true)
  end

  test "requires authentication" do
    get faction_leadership_data_coverage_path(@faction)
    assert_redirected_to new_session_path
  end

  test "requires leadership access" do
    sign_in_as(@bert)
    get faction_leadership_data_coverage_path(@faction)
    assert_redirected_to faction_path(@faction)
  end

  test "shows page for leadership member" do
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

  test "hides members with 100% coverage from table" do
    start_date = PersonalStatSnapshot.tracking_start_date
    (start_date..PersonalStatSnapshot.tracking_end_date).each do |date|
      PersonalStatSnapshot.create!(user: @bram, date: date, timestamp: date.to_time.to_i)
    end

    sign_in_as(@bram)
    get faction_leadership_data_coverage_path(@faction)
    assert_response :success
    assert_select "a.player-link", { text: /Bram/, count: 0 }
  end

  test "shows members with missing days in table" do
    sign_in_as(@bram)
    get faction_leadership_data_coverage_path(@faction)
    assert_response :success
    assert_select "a.player-link", /Bram/
    assert_select "span.stat-danger"
  end

  test "backfill_user schedules jobs and returns json" do
    sign_in_as(@bram)

    relation = mock
    relation.stubs(:count).returns(0)
    SolidQueue::Job.stubs(:where).returns(relation)

    assert_enqueued_with(job: BackfillSingleStatJob) do
      post backfill_user_faction_leadership_data_coverage_path(@faction, user_id: @bert.id)
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert_match /API calls/, json["message"]
  end

  test "redirects to setup when no api keys" do
    @faction.faction_setting.update!(torn_api_key: nil)
    sign_in_as(@bram)
    get faction_leadership_data_coverage_path(@faction)
    assert_redirected_to faction_leadership_setup_path(@faction)
  end
end
