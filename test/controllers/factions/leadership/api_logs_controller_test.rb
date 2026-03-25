require "test_helper"

class Factions::Leadership::ApiLogsControllerTest < ActionDispatch::IntegrationTest
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
    get faction_leadership_api_logs_path(@faction)
    assert_redirected_to new_session_path
  end

  test "requires leadership access" do
    sign_in_as(@bert)
    get faction_leadership_api_logs_path(@faction)
    assert_redirected_to faction_path(@faction)
  end

  test "shows page for leadership member" do
    sign_in_as(@bram)
    get faction_leadership_api_logs_path(@faction)
    assert_response :success
    assert_select "a.back-link", "← Back to Leadership"
  end

  test "shows stats and table when api calls exist" do
    ApiCall.create!(
      user: @bram,
      faction: @faction,
      api_key: "FACTION_KEY_123",
      endpoint: "v2/faction/99999/members",
      status: "success",
      response_time: 150,
      selections: { timestamp: 1234567890 }.to_json
    )

    sign_in_as(@bram)
    get faction_leadership_api_logs_path(@faction)
    assert_response :success
    assert_select "code", "v2/faction/99999/members"
  end

  test "shows empty state when no api calls for faction" do
    sign_in_as(@bram)
    get faction_leadership_api_logs_path(@faction)
    assert_response :success
    assert_select "p", "No API calls recorded for this faction's key."
  end

  test "only shows calls for this faction" do
    ApiCall.create!(
      user: @bram,
      faction: @faction,
      api_key: "FACTION_KEY_123",
      endpoint: "v2/faction/99999/members",
      status: "success",
      response_time: 100
    )

    other_faction = Faction.create!(
      torn_id: 88888, name: "Other Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    ApiCall.create!(
      user: @bram,
      faction: other_faction,
      api_key: "OTHER_KEY_456",
      endpoint: "v2/user/123/personalstats",
      status: "success",
      response_time: 200
    )

    sign_in_as(@bram)
    get faction_leadership_api_logs_path(@faction)
    assert_response :success
    assert_select "code", "v2/faction/99999/members"
    assert_select "code", { count: 0, text: "v2/user/123/personalstats" }
  end
end
