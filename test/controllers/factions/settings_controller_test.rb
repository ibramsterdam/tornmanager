require "test_helper"

class Factions::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999,
      name: "Test Faction",
      track_stats: true,
      xanax_target: 2.5,
      energy_refill_target: 1.0,
      nerve_refill_target: 1.0
    )
    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction)
    @bert.update!(faction: @faction)
  end

  # -- Whitelist management --

  test "leader can add a member to the whitelist" do
    sign_in_as_faction_leader(@bert)

    assert_difference -> { @faction.faction_whitelists.count }, 1 do
      post add_whitelist_faction_settings_path(@faction), params: { user_id: @bram.id }
    end

    assert_redirected_to faction_settings_path(@faction)
    assert @faction.faction_whitelists.exists?(user: @bram)
    assert_match /Bram has been granted access/, flash[:notice]
  end

  test "leader can remove a member from the whitelist" do
    @faction.faction_whitelists.create!(user: @bram)
    sign_in_as_faction_leader(@bert)

    assert_difference -> { @faction.faction_whitelists.count }, -1 do
      delete remove_whitelist_faction_settings_path(@faction), params: { user_id: @bram.id }
    end

    assert_redirected_to faction_settings_path(@faction)
    assert_not @faction.faction_whitelists.exists?(user: @bram)
    assert_match /access has been removed/, flash[:notice]
  end

  test "adding already whitelisted member shows notice" do
    @faction.faction_whitelists.create!(user: @bram)
    sign_in_as_faction_leader(@bert)

    assert_no_difference -> { @faction.faction_whitelists.count } do
      post add_whitelist_faction_settings_path(@faction), params: { user_id: @bram.id }
    end

    assert_match /already has access/, flash[:notice]
  end

  test "adding user not in faction shows error" do
    sign_in_as_faction_leader(@bert)

    post add_whitelist_faction_settings_path(@faction), params: { user_id: 999999 }
    assert_match /User not found/, flash[:alert]
  end

  test "admin can access settings without leader role check" do
    sign_in_as(@bram)
    get faction_settings_path(@faction)
    assert_response :success
  end

  test "settings shows whitelist section" do
    @faction.faction_whitelists.create!(user: @bram)
    sign_in_as_faction_leader(@bert)

    get faction_settings_path(@faction)
    assert_response :success
    assert_select ".whitelist-item", 1
    assert_match /Bram/, response.body
  end

  test "non-leader member cannot access settings" do
    sign_in_as(@bert)

    stub_faction_members(@bert, "Member")

    get faction_settings_path(@faction)
    assert_redirected_to faction_path(@faction)
    assert_match /Only faction leaders/, flash[:alert]
  end

  private

  def sign_in_as_faction_leader(user)
    sign_in_as(user)
    stub_faction_members(user, "Leader")
  end

  def stub_faction_members(user, position)
    member = TornApi::Faction::Members::Member.new(
      user.torn_id, user.name, user.level, 100,
      "Online", Time.current.to_i, "0 seconds ago",
      "Okay", "", "Okay", "green", 0,
      "Everyone", position, true, false, false, false
    )
    members_api = mock
    members_api.stubs(:fetch).returns([ member ])
    TornApi::Faction::Members.stubs(:new).with(user.api_key, @faction.torn_id).returns(members_api)
  end
end
