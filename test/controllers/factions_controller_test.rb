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

  # -- Setup wizard (faction not in DB) --

  test "shows setup wizard when faction not in DB and torn_faction_id in session" do
    @bert.update!(faction: nil)
    sign_in_with_faction_id(@bert, 55555)

    get faction_path(torn_id: 55555)
    assert_response :success
    assert_select "h1", "Set Up Your Faction"
    assert_select ".setup-info-list li", 4
  end

  test "redirects to root when faction not in DB and torn_faction_id does not match" do
    @bert.update!(faction: nil)
    sign_in_with_faction_id(@bert, 55555)

    get faction_path(torn_id: 77777)
    assert_redirected_to root_path
  end

  test "shows dashboard when faction exists in DB even with setup session" do
    sign_in_with_faction_id(@bert, @faction.torn_id)

    get faction_path(@faction)
    assert_response :success
    assert_select ".dashboard-hero"
  end

  test "prefills api key on setup when user has limited access" do
    @bert.update!(faction: nil)
    sign_in_with_faction_id(@bert, 55555, access_type: "Limited Access")

    get faction_path(torn_id: 55555)
    assert_response :success
    assert_select "input[value='#{@bert.api_key}']"
  end

  # -- Setup create: validation errors --

  test "setup shows error for invalid api key" do
    @bert.update!(faction: nil)
    sign_in_with_faction_id(@bert, 55555)
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError)

    post setup_faction_path(torn_id: 55555), params: { api_key: "BAD_KEY" }
    assert_response :unprocessable_entity
    assert_select ".setup-error", /Invalid API key/
  end

  test "setup shows error when key is not limited access" do
    @bert.update!(faction: nil)
    sign_in_with_faction_id(@bert, 55555)

    minimal_key = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 1, type: "Public Only", faction: false, company: false),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: 55555, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(minimal_key)

    post setup_faction_path(torn_id: 55555), params: { api_key: "PUBLIC_KEY" }
    assert_response :unprocessable_entity
    assert_select ".setup-error", /Limited Access key is required/
  end

  test "setup shows error when key belongs to different user" do
    @bert.update!(faction: nil)
    sign_in_with_faction_id(@bert, 55555)

    other_user_key = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 9999999, faction_id: 55555, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(other_user_key)

    post setup_faction_path(torn_id: 55555), params: { api_key: "OTHER_KEY" }
    assert_response :unprocessable_entity
    assert_select ".setup-error", /does not belong to you/
  end

  test "setup shows error when key is for different faction" do
    @bert.update!(faction: nil)
    sign_in_with_faction_id(@bert, 55555)

    wrong_faction_key = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: 99999, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(wrong_faction_key)

    post setup_faction_path(torn_id: 55555), params: { api_key: "WRONG_FACTION_KEY" }
    assert_response :unprocessable_entity
    assert_select ".setup-error", /different faction/
  end

  # -- Setup create: success --

  test "setup creates faction, setting, whitelist and queues jobs" do
    @bert.update!(faction: nil)
    sign_in_with_faction_id(@bert, 55555)

    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: 55555, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)
    TornApi::Faction::Basic.any_instance.stubs(:fetch).returns({ "name" => "New Faction" })
    SyncFactionMembersJob.stubs(:perform_now)

    assert_difference "Faction.count", 1 do
      assert_difference "FactionSetting.count", 1 do
        assert_difference "FactionWhitelist.count", 1 do
          post setup_faction_path(torn_id: 55555), params: { api_key: "VALID_LIMITED_KEY" }
        end
      end
    end

    faction = Faction.find_by(torn_id: 55555)
    assert_not_nil faction
    assert_equal "New Faction", faction.name
    assert faction.track_stats

    assert_equal "VALID_LIMITED_KEY", faction.faction_setting.torn_api_key
    assert_equal "Limited Access", faction.faction_setting.torn_api_access_type

    assert_equal faction.id, @bert.reload.faction_id
    assert faction.faction_whitelists.exists?(user: @bert)

    assert_redirected_to faction_path(faction)
    assert_match /Welcome to TornManager/, flash[:notice]
  end

  test "setup handles race condition when faction created between show and create" do
    @bert.update!(faction: nil)
    sign_in_with_faction_id(@bert, 55555)

    existing = Faction.create!(torn_id: 55555, name: "Race Condition Faction", track_stats: true, xanax_target: 2.5)

    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: 55555, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)
    SyncFactionMembersJob.stubs(:perform_now)

    assert_no_difference "Faction.count" do
      post setup_faction_path(torn_id: 55555), params: { api_key: "VALID_LIMITED_KEY" }
    end

    assert_equal existing.id, @bert.reload.faction_id
    assert existing.faction_whitelists.exists?(user: @bert)
    assert_redirected_to faction_path(existing)
  end
end
