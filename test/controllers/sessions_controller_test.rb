require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_api_key = "test_api_key_valid"
    @invalid_api_key = "test_api_key_invalid"
    @existing_user = users(:one)
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

  test "create rejects non-Limited Access API keys" do
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

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock_key_info)

    assert_no_difference "User.count" do
      assert_no_difference "Session.count" do
        post session_path, params: { api_key: @valid_api_key }
      end
    end

    assert_redirected_to new_session_path
    assert_equal "Please use a Limited Access API key. Your key has Full Access.", flash[:alert]
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

  test "destroy terminates session and redirects to root" do
    user = users(:one)
    sign_in_as(user)
    session_count_before = user.sessions.count

    assert_difference "Session.count", -1 do
      delete session_path
    end

    assert_redirected_to root_path
    assert_equal session_count_before - 1, user.sessions.count
  end

  test "destroy uses see_other status" do
    sign_in_as(users(:one))

    delete session_path

    assert_response :see_other
  end
end
