require "test_helper"

class FactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @faction = Faction.create!(
      torn_id: 99999,
      name: "Test Faction",
      track_stats: true,
      xanax_target: 2.5,
      energy_refill_target: 1.0,
      nerve_refill_target: 1.0,
      setup_completed: true
    )
    @bram = users(:bram)
    @bert = users(:bert)
    @bram.update!(faction: @faction, subscription_expires_at: 1.month.from_now)
    @bert.update!(faction: @faction, subscription_expires_at: 1.month.from_now)
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

  # -- War record shows only current year --

  test "war record card only counts wars from current year" do
    # 2026 wars
    @faction.ranked_wars.create!(
      torn_war_id: 1001, opponent_faction_id: 88888, opponent_faction_name: "Enemy A",
      started_at: Date.new(2026, 1, 15).to_time, ended_at: Date.new(2026, 1, 16).to_time,
      target_score: 100, our_score: 100, their_score: 50,
      winner_faction_id: @faction.torn_id
    )
    @faction.ranked_wars.create!(
      torn_war_id: 1002, opponent_faction_id: 77777, opponent_faction_name: "Enemy B",
      started_at: Date.new(2026, 2, 10).to_time, ended_at: Date.new(2026, 2, 11).to_time,
      target_score: 100, our_score: 50, their_score: 100,
      winner_faction_id: 77777
    )
    # 2025 war (should be excluded)
    @faction.ranked_wars.create!(
      torn_war_id: 999, opponent_faction_id: 66666, opponent_faction_name: "Old Enemy",
      started_at: Date.new(2025, 6, 1).to_time, ended_at: Date.new(2025, 6, 2).to_time,
      target_score: 100, our_score: 100, their_score: 50,
      winner_faction_id: @faction.torn_id
    )

    sign_in_as(@bram)
    get faction_path(@faction)
    assert_response :success

    # Should show 1W / 1L (only 2026 wars), not 2W / 1L
    assert_select ".stat-wins", "1"
    assert_select ".stat-losses", "1"
  end

  # -- Compliance card during backfill --

  test "compliance card shows placeholder during backfill" do
    @faction.update!(backfill_ends_at: 1.hour.from_now, backfill_target_date: Date.new(2026, 1, 1))
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_response :success

    # Should show dashes instead of numbers
    assert_select ".stat-compliant", "--"
    assert_select ".stat-warning", "--"
    assert_select ".stat-danger", "--"
  end

  test "compliance card shows real numbers when backfill is complete" do
    @faction.update!(backfill_ends_at: nil, backfill_target_date: nil)
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_response :success

    # Should show actual numbers (may be 0, but as "0" not "--")
    assert_select ".stat-compliant", /\d+/
  end

  # -- Index redirect --

  test "index redirects to faction page for member with faction" do
    sign_in_as(@bram)
    get factions_path
    assert_redirected_to faction_path(@faction)
  end

  test "index redirects to stocks when user has no faction" do
    @bram.update!(faction: nil)
    sign_in_as(@bram)
    get factions_path
    assert_redirected_to stocks_path
  end

  # -- Subscription check --

  test "shows subscription expired page when user has no subscription" do
    @bert.update!(subscription_expires_at: 1.day.ago)
    sign_in_as(@bert)
    get faction_path(@faction)
    assert_response :success
    assert_select "h1", "Subscription Expired"
  end

  test "admin bypasses subscription check" do
    @bram.update!(subscription_expires_at: nil)
    sign_in_as(@bram)
    get faction_path(@faction)
    assert_response :success
    assert_select ".dashboard-hero"
  end

  # -- Setup wizard (faction exists but setup_completed: false) --

  test "dashboard redirects to setup when faction setup not completed" do
    setup_faction = Faction.create!(
      torn_id: 55555, name: "New Faction", xanax_target: 2.5, setup_completed: false
    )
    @bert.update!(faction: setup_faction)
    sign_in_as(@bert)

    get faction_path(setup_faction)
    assert_redirected_to setup_faction_path(setup_faction)
  end

  test "setup page shows setup wizard" do
    setup_faction = Faction.create!(
      torn_id: 55555, name: "New Faction", xanax_target: 2.5, setup_completed: false
    )
    @bert.update!(faction: setup_faction)
    sign_in_as(@bert)

    get setup_faction_path(setup_faction)
    assert_response :success
    assert_select "h1", "Set Up Your Faction"
    assert_select ".setup-subtitle", "New Faction"
  end

  test "prefills api key on setup when user has limited access" do
    setup_faction = Faction.create!(
      torn_id: 55555, name: "New Faction", xanax_target: 2.5, setup_completed: false
    )
    @bert.update!(faction: setup_faction, api_access_type: "Limited Access")
    sign_in_as(@bert)

    get setup_faction_path(setup_faction)
    assert_response :success
    assert_select "input[value='#{@bert.api_key}']"
  end

  test "shows dashboard when faction setup is completed" do
    sign_in_as(@bert)
    get faction_path(@faction)
    assert_response :success
    assert_select ".dashboard-hero"
  end

  test "setup page redirects to dashboard when already completed" do
    sign_in_as(@bert)
    get setup_faction_path(@faction)
    assert_redirected_to root_path
  end

  # -- Setup create: validation errors --

  test "setup shows error for invalid api key" do
    setup_faction = Faction.create!(
      torn_id: 55555, name: "New Faction", xanax_target: 2.5, setup_completed: false
    )
    @bert.update!(faction: setup_faction)
    sign_in_as(@bert)
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError)

    post setup_faction_path(torn_id: 55555), params: { api_key: "BAD_KEY" }
    assert_response :unprocessable_entity
    assert_match /Invalid API key/, flash[:alert]
  end

  test "setup shows error when key is not limited access" do
    setup_faction = Faction.create!(
      torn_id: 55555, name: "New Faction", xanax_target: 2.5, setup_completed: false
    )
    @bert.update!(faction: setup_faction)
    sign_in_as(@bert)

    minimal_key = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 1, type: "Public Only", faction: false, company: false),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: 55555, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(minimal_key)

    post setup_faction_path(torn_id: 55555), params: { api_key: "PUBLIC_KEY" }
    assert_response :unprocessable_entity
    assert_match /Limited Access key is required/, flash[:alert]
  end

  test "setup shows error when key belongs to different user" do
    setup_faction = Faction.create!(
      torn_id: 55555, name: "New Faction", xanax_target: 2.5, setup_completed: false
    )
    @bert.update!(faction: setup_faction)
    sign_in_as(@bert)

    other_user_key = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 9999999, faction_id: 55555, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(other_user_key)

    post setup_faction_path(torn_id: 55555), params: { api_key: "OTHER_KEY" }
    assert_response :unprocessable_entity
    assert_match /does not belong to you/, flash[:alert]
  end

  test "setup shows error when key is for different faction" do
    setup_faction = Faction.create!(
      torn_id: 55555, name: "New Faction", xanax_target: 2.5, setup_completed: false
    )
    @bert.update!(faction: setup_faction)
    sign_in_as(@bert)

    wrong_faction_key = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: 99999, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(wrong_faction_key)

    post setup_faction_path(torn_id: 55555), params: { api_key: "WRONG_FACTION_KEY" }
    assert_response :unprocessable_entity
    assert_match /different faction/, flash[:alert]
  end

  # -- Setup create: success --

  test "setup completes faction setup, creates setting, whitelist and queues jobs" do
    setup_faction = Faction.create!(
      torn_id: 55555, name: "New Faction", xanax_target: 2.5, setup_completed: false
    )
    @bert.update!(faction: setup_faction)
    sign_in_as(@bert)

    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: 55555, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)

    assert_no_difference "Faction.count" do
      assert_difference "FactionSetting.count", 1 do
        assert_difference "FactionWhitelist.count", 1 do
          post setup_faction_path(torn_id: 55555), params: { api_key: "VALID_LIMITED_KEY" }
        end
      end
    end

    setup_faction.reload
    assert setup_faction.setup_completed, "Faction should be marked as setup completed"
    assert_equal "VALID_LIMITED_KEY", setup_faction.faction_setting.torn_api_key
    assert_equal "Limited Access", setup_faction.faction_setting.torn_api_access_type
    assert setup_faction.faction_whitelists.exists?(user: @bert)

    assert_redirected_to faction_path(setup_faction)
    assert_match /Welcome to TornManager/, flash[:notice]
  end

  test "setup sets backfill_ends_at immediately before background job runs" do
    setup_faction = Faction.create!(
      torn_id: 55555, name: "New Faction", xanax_target: 2.5, setup_completed: false
    )
    @bert.update!(faction: setup_faction)
    sign_in_as(@bert)

    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: 55555, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)

    post setup_faction_path(torn_id: 55555), params: { api_key: "VALID_LIMITED_KEY" }

    setup_faction.reload
    assert_not_nil setup_faction.backfill_ends_at, "backfill_ends_at should be set immediately"
    assert setup_faction.backfill_ends_at > Time.current, "backfill_ends_at should be in the future"
    assert_not_nil setup_faction.backfill_target_date, "backfill_target_date should be set immediately"
  end

  test "setup rejects when user is not a member of the faction" do
    setup_faction = Faction.create!(
      torn_id: 55555, name: "New Faction", xanax_target: 2.5, setup_completed: false
    )
    # bert is NOT a member of setup_faction
    sign_in_as(@bert)

    post setup_faction_path(torn_id: 55555), params: { api_key: "VALID_LIMITED_KEY" }
    assert_redirected_to root_path
  end

  test "setup rejects when faction is already set up" do
    sign_in_as(@bert)

    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: @faction.torn_id, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)

    post setup_faction_path(torn_id: @faction.torn_id), params: { api_key: "VALID_LIMITED_KEY" }
    assert_redirected_to root_path
  end
end
