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

  test "non-whitelisted member can access faction dashboard" do
    sign_in_as(@bert)
    get faction_path(@faction)
    assert_response :success
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
    assert_select ".dashboard-stats-grid"
    assert_select ".dashboard-stat-card", 4
    assert_select ".compliance-summary"
  end

  test "dashboard shows faction targets" do
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_select ".target-info li", /Xanax.*2\.5\/day/
    assert_select ".target-info li", /Energy Refills.*1\.0\/day/
    assert_select ".target-info li", /Nerve Refills.*1\.0\/day/
  end

  test "dashboard shows tracking disabled when faction not tracked" do
    @faction.update!(track_stats: false)
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_response :success
    assert_select ".info-card", /Stats Tracking Disabled/
    assert_select ".dashboard-stats-row", count: 0
  end

  test "dashboard shows scroll cards for navigation" do
    sign_in_as(@bert)
    get faction_path(@faction)
    assert_response :success
    assert_select ".dashboard-scroll-card", 2
  end

  test "dashboard shows hero section with stats grid for admin" do
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_response :success
    assert_select ".dashboard-hero"
    assert_select ".dashboard-stats-grid"
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
