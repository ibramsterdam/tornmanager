require "test_helper"

class Factions::SetupControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bert)
    @user.update!(faction: nil)

    @key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: @user.torn_id, faction_id: 55555, company_id: 0)
    )
  end

  # -- Authentication --

  test "redirects to login when not authenticated" do
    get faction_setup_path
    assert_redirected_to new_session_path
  end

  # -- Show --

  test "redirects to stocks when no torn_faction_id in session" do
    sign_in_as(@user)
    get faction_setup_path
    assert_redirected_to stocks_path
  end

  test "shows setup wizard when torn_faction_id is in session" do
    sign_in_with_faction_id(@user, 55555)

    get faction_setup_path
    assert_response :success
    assert_select "h1", "Set Up Your Faction"
    assert_select ".setup-info-list li", 4
  end

  test "redirects to dashboard if faction already exists" do
    faction = Faction.create!(torn_id: 55555, name: "Existing Faction", track_stats: true, xanax_target: 2.5)
    sign_in_with_faction_id(@user, 55555)

    get faction_setup_path
    assert_redirected_to faction_path(faction)
    assert_equal faction.id, @user.reload.faction_id
  end

  test "prefills api key when user has limited access" do
    sign_in_with_faction_id(@user, 55555, access_type: "Limited Access")

    get faction_setup_path
    assert_response :success
    assert_select "input[value='#{@user.api_key}']"
  end

  # -- Create: validation errors --

  test "shows error for invalid api key" do
    sign_in_with_faction_id(@user, 55555)
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError)

    post faction_setup_path, params: { api_key: "BAD_KEY" }
    assert_response :unprocessable_entity
    assert_select ".setup-error", /Invalid API key/
  end

  test "shows error when key is not limited access" do
    sign_in_with_faction_id(@user, 55555)

    minimal_key = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 1, type: "Public Only", faction: false, company: false),
      user: TornApi::Key::Info::UserData.new(id: @user.torn_id, faction_id: 55555, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(minimal_key)

    post faction_setup_path, params: { api_key: "PUBLIC_KEY" }
    assert_response :unprocessable_entity
    assert_select ".setup-error", /Limited Access key is required/
  end

  test "shows error when key belongs to different user" do
    sign_in_with_faction_id(@user, 55555)

    other_user_key = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 9999999, faction_id: 55555, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(other_user_key)

    post faction_setup_path, params: { api_key: "OTHER_KEY" }
    assert_response :unprocessable_entity
    assert_select ".setup-error", /does not belong to you/
  end

  test "shows error when key is for different faction" do
    sign_in_with_faction_id(@user, 55555)

    wrong_faction_key = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: @user.torn_id, faction_id: 99999, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(wrong_faction_key)

    post faction_setup_path, params: { api_key: "WRONG_FACTION_KEY" }
    assert_response :unprocessable_entity
    assert_select ".setup-error", /different faction/
  end

  # -- Create: success --

  test "creates faction, setting, whitelist and queues jobs on valid setup" do
    sign_in_with_faction_id(@user, 55555)

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(@key_info)
    TornApi::Faction::Basic.any_instance.stubs(:fetch).returns({ "name" => "New Faction" })
    SyncFactionMembersJob.stubs(:perform_now)

    assert_difference "Faction.count", 1 do
      assert_difference "FactionSetting.count", 1 do
        assert_difference "FactionWhitelist.count", 1 do
          post faction_setup_path, params: { api_key: "VALID_LIMITED_KEY" }
        end
      end
    end

    faction = Faction.find_by(torn_id: 55555)
    assert_not_nil faction
    assert_equal "New Faction", faction.name
    assert faction.track_stats

    assert_equal "VALID_LIMITED_KEY", faction.faction_setting.torn_api_key
    assert_equal "Limited Access", faction.faction_setting.torn_api_access_type

    assert_equal faction.id, @user.reload.faction_id
    assert faction.faction_whitelists.exists?(user: @user)

    assert_redirected_to faction_path(faction)
    assert_match /Welcome to TornManager/, flash[:notice]
  end

  test "handles race condition when faction created between show and create" do
    sign_in_with_faction_id(@user, 55555)

    existing = Faction.create!(torn_id: 55555, name: "Race Condition Faction", track_stats: true, xanax_target: 2.5)

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(@key_info)
    SyncFactionMembersJob.stubs(:perform_now)

    assert_no_difference "Faction.count" do
      post faction_setup_path, params: { api_key: "VALID_LIMITED_KEY" }
    end

    assert_equal existing.id, @user.reload.faction_id
    assert existing.faction_whitelists.exists?(user: @user)
    assert_redirected_to faction_path(existing)
  end

  private

  def sign_in_with_faction_id(user, torn_faction_id, access_type: "Public Only")
    sign_in_as(user)

    # Simulate the session state that SessionsController would set during login.
    # Since integration tests can't set session directly, we stub the login flow:
    # POST to sessions#create which sets session[:torn_faction_id].
    access_level = access_type == "Limited Access" ? 3 : 1
    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: access_level, type: access_type, faction: false, company: false),
      user: TornApi::Key::Info::UserData.new(id: user.torn_id, faction_id: torn_faction_id, company_id: 0)
    )
    profile = TornApi::User::Profile::ProfileData.new(
      id: user.torn_id, name: user.name, level: user.level, image: nil
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(profile)

    post session_path, params: { api_key: user.api_key, terms_accepted: "1" }

    # Unstub so subsequent test calls can set their own stubs
    TornApi::Key::Info.any_instance.unstub(:fetch)
    TornApi::User::Profile.any_instance.unstub(:fetch)
  end
end
