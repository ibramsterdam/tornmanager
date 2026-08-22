require "test_helper"

class Api::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 2728237, faction_id: 99999, company_id: nil)
    )

    @profile = TornApi::User::Profile::ProfileData.new(
      id: 2728237,
      name: "Bram",
      level: 69,
      image: "https://profileimages.torn.com/abc.jpg"
    )
  end

  test "creates session for existing user" do
    bram = users(:bram)
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(@key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(@profile)

    post api_session_path, params: { api_key: "valid_key_123" }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2728237, json.dig("user", "torn_id")
    assert_equal "Bram", json.dig("user", "name")
    assert_equal 69, json.dig("user", "level")
    assert_equal "https://profileimages.torn.com/abc.jpg", json.dig("user", "profile_image")

    bram.reload
    assert_equal bram.api_token, json["token"]
    assert_equal "valid_key_123", bram.api_key
    assert_equal "Limited Access", bram.api_access_type
  end

  test "keeps the existing token across sign-ins so other scripts stay signed in" do
    bram = users(:bram)
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(@key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(@profile)

    post api_session_path, params: { api_key: "valid_key_123" }, as: :json

    assert_response :ok
    assert_equal bram.api_token, JSON.parse(response.body)["token"]
  end

  test "generates a token for users that have none yet" do
    bram = users(:bram)
    bram.update_column(:api_token, nil)
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(@key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(@profile)

    post api_session_path, params: { api_key: "valid_key_123" }, as: :json

    assert_response :ok
    token = JSON.parse(response.body)["token"]
    assert token.present?
    assert_equal token, bram.reload.api_token
  end

  test "rejects Full Access keys" do
    full_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 4, type: "Full Access", faction: true, company: true),
      user: TornApi::Key::Info::UserData.new(id: 2728237, faction_id: 99999, company_id: nil)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(full_key_info)

    post api_session_path, params: { api_key: "full_access_key" }, as: :json

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_match /Full Access keys are not allowed/, json["error"]
  end

  test "creates new user when torn_id not found" do
    profile = TornApi::User::Profile::ProfileData.new(
      id: 5555555,
      name: "NewPlayer",
      level: 10,
      image: "https://profileimages.torn.com/new.jpg"
    )
    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 5555555, faction_id: nil, company_id: nil)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(profile)

    assert_difference "User.count", 1 do
      post api_session_path, params: { api_key: "new_user_key" }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 5555555, json.dig("user", "torn_id")
    assert_equal "NewPlayer", json.dig("user", "name")
  end

  test "returns error when api key is blank" do
    post api_session_path, params: { api_key: "" }, as: :json

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "API key is required", json["error"]
  end

  test "returns error when api key is missing" do
    post api_session_path, params: {}, as: :json

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "API key is required", json["error"]
  end

  test "returns error for invalid torn api key" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "Invalid key")

    post api_session_path, params: { api_key: "bad_key" }, as: :json

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "Invalid Torn API key", json["error"]
  end

  test "updates existing user profile data on login" do
    bram = users(:bram)
    old_name = bram.name

    updated_profile = TornApi::User::Profile::ProfileData.new(
      id: 2728237,
      name: "BramRenamed",
      level: 99,
      image: "https://profileimages.torn.com/updated.jpg"
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(@key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(updated_profile)

    post api_session_path, params: { api_key: "updated_key" }, as: :json

    assert_response :ok
    bram.reload
    assert_equal "BramRenamed", bram.name
    assert_equal 99, bram.level
    assert_equal "updated_key", bram.api_key
  end

  test "returns error on unexpected api failure" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(StandardError, "Connection refused")

    post api_session_path, params: { api_key: "some_key" }, as: :json

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "Unexpected error. Please try again.", json["error"]
  end
end
