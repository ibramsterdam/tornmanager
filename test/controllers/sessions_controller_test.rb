require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_api_key = "test_api_key_valid"
    @invalid_api_key = "test_api_key_invalid"
    @existing_user = users(:bram)
  end

  test "new shows login page" do
    get new_session_path
    assert_response :success
  end

  test "create with valid API key and Limited Access creates new user and session" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(
        level: 1,
        type: "Limited Access",
        faction: false,
        company: false
      ),
      user: TornApi::Key::Info::UserData.new(
        id: 9999999,
        faction_id: nil,
        company_id: nil
      )
    )

    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: 9999999,
      name: "NewUser",
      level: 25,
      image: "https://example.com/image.jpg"
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)

    assert_difference "User.count", 1 do
      assert_difference "Session.count", 1 do
        post session_path, params: { api_key: @valid_api_key }
      end
    end

    assert_redirected_to root_url

    user = User.find_by(torn_id: 9999999)
    assert_not_nil user
    assert_equal "NewUser", user.name
    assert_equal 25, user.level
    assert_equal @valid_api_key, user.api_key
    assert_equal "https://example.com/image.jpg", user.profile_image
    assert_not_nil user.sessions.last
  end

  test "create with valid API key updates existing user with new api_key when torn_id matches" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(
        level: 1,
        type: "Limited Access",
        faction: false,
        company: false
      ),
      user: TornApi::Key::Info::UserData.new(
        id: @existing_user.torn_id,
        faction_id: nil,
        company_id: nil
      )
    )

    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: @existing_user.torn_id,
      name: "UpdatedName",
      level: 70,
      image: "https://example.com/new_image.jpg"
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)

    new_api_key = "brand_new_api_key"

    assert_no_difference "User.count" do
      assert_difference "Session.count", 1 do
        post session_path, params: { api_key: new_api_key }
      end
    end

    assert_redirected_to root_url

    @existing_user.reload
    assert_equal new_api_key, @existing_user.api_key
    assert_equal "UpdatedName", @existing_user.name
    assert_equal 70, @existing_user.level
    assert_equal "https://example.com/new_image.jpg", @existing_user.profile_image
  end

  test "create accepts Full Access API keys and stores access type" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(
        level: 4,
        type: "Full Access",
        faction: true,
        company: true
      ),
      user: TornApi::Key::Info::UserData.new(
        id: 9999999,
        faction_id: 123,
        company_id: 456
      )
    )

    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: 9999999,
      name: "FullAccessUser",
      level: 50,
      image: "https://example.com/full_access.jpg"
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)
    TornApi::Faction::Basic.any_instance.stubs(:name).returns("Full Access Faction")
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([])
    OwnerCredentials.stubs(:api_key).returns("owner_key")

    assert_difference "User.count", 1 do
      assert_difference "Session.count", 1 do
        post session_path, params: { api_key: @valid_api_key, terms_accepted: "1" }
      end
    end

    assert_redirected_to root_path
    new_user = User.find_by(torn_id: 9999999)
    assert_equal "Full Access", new_user.api_access_type
    assert new_user.has_limited_access?, "Full Access should count as having limited access"
  end

  test "create accepts Public Only API keys and stores access type" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(
        level: 1,
        type: "Public Only",
        faction: false,
        company: false
      ),
      user: TornApi::Key::Info::UserData.new(
        id: 8888888,
        faction_id: nil,
        company_id: nil
      )
    )

    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: 8888888,
      name: "PublicOnlyUser",
      level: 30,
      image: "https://example.com/public_only.jpg"
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)

    assert_difference "User.count", 1 do
      assert_difference "Session.count", 1 do
        post session_path, params: { api_key: @valid_api_key, terms_accepted: "1" }
      end
    end

    assert_redirected_to root_path
    new_user = User.find_by(torn_id: 8888888)
    assert_equal "Public Only", new_user.api_access_type
    assert_not new_user.has_limited_access?, "Public Only should not count as having limited access"
  end

  test "create handles invalid API key error" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError)

    assert_no_difference "User.count" do
      assert_no_difference "Session.count" do
        post session_path, params: { api_key: @invalid_api_key }
      end
    end

    assert_redirected_to new_session_path
    assert_equal "Invalid Torn API key.", flash[:alert]
  end

  test "create handles profile fetch failure" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(
        level: 1,
        type: "Limited Access",
        faction: false,
        company: false
      ),
      user: TornApi::Key::Info::UserData.new(
        id: 9999999,
        faction_id: nil,
        company_id: nil
      )
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(nil)

    assert_no_difference "User.count" do
      assert_no_difference "Session.count" do
        post session_path, params: { api_key: @valid_api_key }
      end
    end

    assert_redirected_to new_session_path
    assert_equal "Could not fetch profile from Torn API.", flash[:alert]
  end

  test "create handles user validation errors" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(
        level: 1,
        type: "Limited Access",
        faction: false,
        company: false
      ),
      user: TornApi::Key::Info::UserData.new(
        id: nil,
        faction_id: nil,
        company_id: nil
      )
    )

    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: nil,
      name: "TestUser",
      level: 25,
      image: "https://example.com/image.jpg"
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)

    assert_no_difference "User.count" do
      assert_no_difference "Session.count" do
        post session_path, params: { api_key: @valid_api_key }
      end
    end

    assert_redirected_to new_session_path
    assert_equal "Could not create user profile.", flash[:alert]
  end

  test "create handles unexpected errors gracefully" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(StandardError.new("Unexpected error"))

    assert_no_difference "User.count" do
      assert_no_difference "Session.count" do
        post session_path, params: { api_key: @valid_api_key }
      end
    end

    assert_redirected_to new_session_path
    assert_equal "Unexpected error. Please try again.", flash[:alert]
  end

  test "create strips whitespace from api_key parameter" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(
        level: 1,
        type: "Limited Access",
        faction: false,
        company: false
      ),
      user: TornApi::Key::Info::UserData.new(
        id: 8888888,
        faction_id: nil,
        company_id: nil
      )
    )

    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: 8888888,
      name: "WhitespaceUser",
      level: 30,
      image: "https://example.com/image.jpg"
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)

    post session_path, params: { api_key: "  trimmed_key  " }

    user = User.find_by(torn_id: 8888888)
    assert_not_nil user
    assert_equal "trimmed_key", user.api_key
  end

  # -- Faction creation on login --

  test "create creates faction and syncs members when faction not in DB" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 9999999, faction_id: 77777, company_id: nil)
    )
    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: 9999999, name: "NewFactionUser", level: 40, image: nil
    )
    mock_members = [
      TornApi::Faction::Members::Member.new(8888888, "MemberOne", 30, 100, nil, nil, nil, nil, nil, "Okay", nil, nil, nil, nil, "Member", nil, nil, nil, nil),
      TornApi::Faction::Members::Member.new(9999999, "NewFactionUser", 40, 50, nil, nil, nil, nil, nil, "Okay", nil, nil, nil, nil, "Member", nil, nil, nil, nil)
    ]

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)
    TornApi::Faction::Basic.any_instance.stubs(:name).returns("Nuclear Wolves")
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns(mock_members)
    OwnerCredentials.stubs(:api_key).returns("owner_key")

    assert_difference "Faction.count", 1 do
      post session_path, params: { api_key: @valid_api_key }
    end

    faction = Faction.find_by(torn_id: 77777)
    assert_not_nil faction
    assert_equal "Nuclear Wolves", faction.name
    assert_not faction.setup_completed, "Faction should not be marked as setup completed"

    user = User.find_by(torn_id: 9999999)
    assert_equal faction.id, user.faction_id

    # Verify members were synced
    member = User.find_by(torn_id: 8888888)
    assert_not_nil member
    assert_equal faction.id, member.faction_id
    assert_equal "MemberOne", member.name
  end

  test "create syncs members without scheduling backfills for new faction on login" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 9999999, faction_id: 77777, company_id: nil)
    )
    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: 9999999, name: "NewFactionUser", level: 40, image: nil
    )
    mock_members = [
      TornApi::Faction::Members::Member.new(8888888, "MemberOne", 30, 100, nil, nil, nil, nil, nil, "Okay", nil, nil, nil, nil, "Member", nil, nil, nil, nil)
    ]

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)
    TornApi::Faction::Basic.any_instance.stubs(:name).returns("Nuclear Wolves")
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns(mock_members)
    OwnerCredentials.stubs(:api_key).returns("owner_key")

    # Backfill jobs should NOT be enqueued during login sync
    BackfillUserStatsJob.expects(:perform_later).never

    post session_path, params: { api_key: @valid_api_key }

    member = User.find_by(torn_id: 8888888)
    assert_nil member.backfill_ends_at, "No backfill should be scheduled during login sync"
  end

  test "create assigns user to existing faction without creating a new one" do
    existing_faction = Faction.create!(torn_id: 88888, name: "Existing Faction", xanax_target: 2.5, setup_completed: true)

    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 9999999, faction_id: 88888, company_id: nil)
    )
    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: 9999999, name: "ExistingFactionUser", level: 40, image: nil
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)

    assert_no_difference "Faction.count" do
      post session_path, params: { api_key: @valid_api_key }
    end

    user = User.find_by(torn_id: 9999999)
    assert_equal existing_faction.id, user.faction_id
  end

  test "create still succeeds when faction API call fails during login" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 9999999, faction_id: 77777, company_id: nil)
    )
    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: 9999999, name: "FailedFactionUser", level: 40, image: nil
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)
    TornApi::Faction::Basic.any_instance.stubs(:name).raises(TornApi::ApiError.new("API down"))

    assert_no_difference "Faction.count" do
      post session_path, params: { api_key: @valid_api_key }
    end

    assert_redirected_to root_url
    user = User.find_by(torn_id: 9999999)
    assert_not_nil user
    assert_nil user.faction_id
  end

  test "create does not create faction when user has no faction in Torn" do
    mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 1, type: "Limited Access", faction: false, company: false),
      user: TornApi::Key::Info::UserData.new(id: 9999999, faction_id: nil, company_id: nil)
    )
    mock_profile = TornApi::User::Profile::ProfileData.new(
      id: 9999999, name: "NoFactionUser", level: 40, image: nil
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock_profile)

    assert_no_difference "Faction.count" do
      post session_path, params: { api_key: @valid_api_key }
    end

    user = User.find_by(torn_id: 9999999)
    assert_nil user.faction_id
  end

  test "destroy terminates session and redirects to root" do
    user = users(:bram)
    sign_in_as(user)
    session_count_before = user.sessions.count

    assert_difference "Session.count", -1 do
      delete session_path
    end

    assert_redirected_to root_path
    assert_equal session_count_before - 1, user.sessions.count
  end

  test "destroy uses see_other status" do
    sign_in_as(users(:bram))

    delete session_path

    assert_response :see_other
  end
end
