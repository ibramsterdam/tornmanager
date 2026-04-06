require "test_helper"

class Factions::Leadership::ArmoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @faction.create_faction_setting!
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")

    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction, leadership_access: true)
    @bert.update!(faction: @faction)
    grant_subscription(@faction, expires_at: 1.month.from_now)
  end

  test "requires authentication" do
    get faction_leadership_armory_path(@faction)
    assert_redirected_to new_session_path
  end

  test "requires leadership access" do
    sign_in_as(@bert)
    get faction_leadership_armory_path(@faction)
    assert_redirected_to faction_path(@faction)
  end

  test "show displays armory page" do
    stub_armory_api
    sign_in_as(@bram)
    get faction_leadership_armory_path(@faction)
    assert_response :success
    assert_select "h1", "Armory"
  end

  test "show displays member loans" do
    stub_armory_api(weapons: [
      { "ID" => 26, "name" => "AK-47", "type" => "Primary", "quantity" => 1, "available" => 0, "loaned" => 1, "loaned_to" => @bram.torn_id.to_s }
    ])
    sign_in_as(@bram)
    get faction_leadership_armory_path(@faction)
    assert_response :success
    assert_match(/AK-47/, response.body)
  end

  test "show displays news from database" do
    stub_armory_api(weapons: [
      { "ID" => 26, "name" => "AK-47", "type" => "Primary", "quantity" => 1, "available" => 0, "loaned" => 1, "loaned_to" => @bram.torn_id.to_s }
    ])
    ArmoryNewsEntry.create!(
      faction: @faction, torn_news_id: "abc123", player_id: @bram.torn_id,
      player_name: @bram.name, action: "loaned", item: "AK-47",
      text: "#{@bram.name} loaned 1x AK-47", occurred_at: 1.hour.ago
    )

    sign_in_as(@bram)
    get faction_leadership_armory_path(@faction)
    assert_response :success
    assert_match(/AK-47/, response.body)
  end

  test "shows backfill banner when backfill is pending" do
    stub_armory_api
    @faction.update!(armory_backfill_pending: true)
    sign_in_as(@bram)
    get faction_leadership_armory_path(@faction)
    assert_response :success
    assert_match(/Fetching armoury history/, response.body)
  end

  test "handles API errors gracefully" do
    TornApi::Faction::Armory.any_instance.stubs(:fetch).raises(TornApi::ApiError, "Server error")

    sign_in_as(@bram)
    get faction_leadership_armory_path(@faction)
    assert_redirected_to faction_leadership_path(@faction)
    assert_match(/API error/, flash[:alert])
  end

  test "redirects to setup when no api keys" do
    @faction.torn_api_key&.destroy!
    sign_in_as(@bram)
    get faction_leadership_armory_path(@faction)
    assert_redirected_to faction_leadership_setup_path(@faction)
  end

  private

  def stub_armory_api(weapons: [], armor: [])
    TornApi::Faction::Armory.any_instance.stubs(:fetch).returns({
      "weapons" => weapons,
      "armor" => armor
    })
  end
end
