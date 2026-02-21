require "test_helper"

class FactionsControllerTest < ActionDispatch::IntegrationTest
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

  # -- Access control --

  test "admin can access any faction dashboard without whitelist" do
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_response :success
  end

  test "whitelisted member can access faction dashboard" do
    @faction.faction_whitelists.create!(user: @bert)
    sign_in_as(@bert)
    get faction_path(@faction)
    assert_response :success
  end

  test "non-whitelisted member is blocked from faction dashboard" do
    sign_in_as(@bert)
    get faction_path(@faction)
    assert_redirected_to stocks_path
    assert_equal "You don't have access to this faction's dashboard. Ask your faction leader for access.", flash[:alert]
  end

  test "unauthenticated user is redirected to login" do
    get faction_path(@faction)
    assert_redirected_to new_session_path
  end

  # -- Dashboard content --

  test "dashboard shows compliance summary cards" do
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_response :success
    assert_select ".dashboard-stats-row"
    assert_select ".dashboard-stat-card", 4
    assert_select ".dashboard-targets"
  end

  test "dashboard shows faction targets" do
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_match /Xanax: 2\.5\/day/, response.body
    assert_match /Energy: 1\.0\/day/, response.body
    assert_match /Nerve: 1\.0\/day/, response.body
  end

  test "dashboard shows tracking disabled when faction not tracked" do
    @faction.update!(track_stats: false)
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_response :success
    assert_select ".info-card", /Stats Tracking Disabled/
    assert_select ".dashboard-stats-row", count: 0
  end

  test "dashboard shows more tools section with coming soon badges for non-admin" do
    @faction.faction_whitelists.create!(user: @bert)
    sign_in_as(@bert)
    get faction_path(@faction)
    assert_response :success
    assert_select ".coming-soon-badge", 2
  end

  test "dashboard shows linked feature cards for admin" do
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_response :success
    assert_select ".coming-soon-badge", count: 0
  end

  # -- Index redirect --

  test "index redirects to faction page for member with faction" do
    sign_in_as(@bram)
    get factions_path
    assert_redirected_to faction_path(@faction)
  end

  test "index redirects to root when user has no faction" do
    @bram.update!(faction: nil)
    sign_in_as(@bram)
    get factions_path
    assert_redirected_to root_path
  end
end
