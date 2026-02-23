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

  # -- API key validation --

  test "rejects non-Limited Access torn api key" do
    sign_in_as_faction_leader(@bert)

    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 4, type: "Full Access", faction: true, company: true),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: @faction.torn_id, company_id: nil)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)

    patch faction_settings_path(@faction), params: { faction_setting: { torn_api_key: "full_access_key" } }

    assert_redirected_to faction_settings_path(@faction)
    assert_match /Limited Access/, flash[:alert]
  end

  test "accepts Limited Access torn api key" do
    sign_in_as_faction_leader(@bert)

    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: @bert.torn_id, faction_id: @faction.torn_id, company_id: nil)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)

    patch faction_settings_path(@faction), params: { faction_setting: { torn_api_key: "limited_key_123" } }

    assert_redirected_to faction_settings_path(@faction)
    assert_match /saved successfully/, flash[:notice]

    @faction.reload.faction_setting
    assert_equal "Limited Access", @faction.faction_setting.torn_api_access_type
  end

  # -- Delete keys --

  test "delete torn api key clears key and access type" do
    @faction.create_faction_setting!(torn_api_key: "old_key_123", torn_api_access_type: "Limited Access")
    sign_in_as_faction_leader(@bert)

    delete delete_torn_key_faction_settings_path(@faction)

    assert_redirected_to faction_settings_path(@faction)
    assert_match /Torn API key deleted/, flash[:notice]

    setting = @faction.faction_setting.reload
    assert_nil setting.torn_api_key
    assert_nil setting.torn_api_access_type
  end

  test "delete tornstats api key clears key" do
    @faction.create_faction_setting!(tornstats_api_key: "ts_old_key")
    sign_in_as_faction_leader(@bert)

    delete delete_tornstats_key_faction_settings_path(@faction)

    assert_redirected_to faction_settings_path(@faction)
    assert_match /TornStats API key deleted/, flash[:notice]

    setting = @faction.faction_setting.reload
    assert_nil setting.tornstats_api_key
  end

  # -- Share subscription --

  test "whitelisted member can share subscription evenly across active members" do
    @bram.update!(subscription_expires_at: 100.weeks.from_now)
    @faction.faction_whitelists.create!(user: @bram)
    sign_in_as(@bram)

    post share_subscription_faction_settings_path(@faction), params: { total_weeks: 4 }

    assert_redirected_to faction_settings_path(@faction)
    assert_match /Shared 4 weeks across 2 members \(2 weeks each\)/, flash[:notice]

    @bram.reload
    @bert.reload
    assert @bert.subscribed?
    # Bram: lost 4 weeks, gained 2 back = net -2
    assert @bram.subscribed?
  end

  test "share subscription creates audit records" do
    @bram.update!(subscription_expires_at: 100.weeks.from_now)
    @faction.faction_whitelists.create!(user: @bram)
    sign_in_as(@bram)

    assert_difference -> { FactionSubscriptionGrant.count }, 1 do
      assert_difference -> { SubscriptionGrant.count }, 2 do
        post share_subscription_faction_settings_path(@faction), params: { total_weeks: 2 }
      end
    end

    grant = FactionSubscriptionGrant.last
    assert_equal @faction.torn_id, grant.torn_faction_id
    assert_equal 2, grant.weeks_granted
    assert_equal @bram, grant.granted_by
  end

  test "share subscription excludes fallen members" do
    @bram.update!(subscription_expires_at: 100.weeks.from_now)
    @bert.update!(fallen: true)
    @faction.faction_whitelists.create!(user: @bram)
    sign_in_as(@bram)

    post share_subscription_faction_settings_path(@faction), params: { total_weeks: 1 }

    assert_redirected_to faction_settings_path(@faction)
    assert_match /Shared 1 weeks across 1 members/, flash[:notice]

    @bert.reload
    assert_not @bert.subscribed?, "Fallen member should not receive subscription time"
  end

  test "share subscription rejects uneven split" do
    @bram.update!(subscription_expires_at: 100.weeks.from_now)
    @faction.faction_whitelists.create!(user: @bram)
    sign_in_as(@bram)

    post share_subscription_faction_settings_path(@faction), params: { total_weeks: 3 }

    assert_redirected_to faction_settings_path(@faction)
    assert_match /cannot be split evenly/, flash[:alert]
  end

  test "share subscription rejects insufficient balance" do
    @bram.update!(subscription_expires_at: 1.week.from_now)
    @faction.faction_whitelists.create!(user: @bram)
    sign_in_as(@bram)

    post share_subscription_faction_settings_path(@faction), params: { total_weeks: 4 }

    assert_redirected_to faction_settings_path(@faction)
    assert_match /weeks remaining/, flash[:alert]
  end

  test "share subscription rejects zero weeks" do
    @bram.update!(subscription_expires_at: 100.weeks.from_now)
    @faction.faction_whitelists.create!(user: @bram)
    sign_in_as(@bram)

    post share_subscription_faction_settings_path(@faction), params: { total_weeks: 0 }

    assert_redirected_to faction_settings_path(@faction)
    assert_match /valid number of weeks/, flash[:alert]
  end

  test "non-whitelisted member cannot share subscription" do
    @bert.update!(subscription_expires_at: 100.weeks.from_now)
    sign_in_as(@bert)

    post share_subscription_faction_settings_path(@faction), params: { total_weeks: 2 }

    assert_redirected_to stocks_path
    assert_match /don't have access/, flash[:alert]
  end

  # -- Settings page rendering --

  test "settings shows single spy configuration card with both key fields" do
    sign_in_as(@bram)

    get faction_settings_path(@faction)
    assert_response :success
    assert_select ".spy-config-card", 1
    assert_select ".spy-config-card details summary", /How your API keys are used/
    assert_select ".spy-config-card details .ping-dot", 1
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
      "Okay", "", "Okay", "green", 0, nil,
      "Everyone", position, true, false, false, false
    )
    members_api = mock
    members_api.stubs(:fetch).returns([ member ])
    TornApi::Faction::Members.stubs(:new).with(user.api_key, @faction.torn_id).returns(members_api)
  end
end
