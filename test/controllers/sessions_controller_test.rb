require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    @mock_profile = {
      "id" => @user.torn_id,
      "name" => @user.name,
      "api_key" => @user.api_key,
      "level" => @user.level,
      "gender" => @user.gender,
    }
  end

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    mock_profile = @mock_profile
    TornApi::Profile.any_instance.stubs(:fetch).returns(@mock_profile)
    post session_path, params: { api_key: @user.api_key }
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { api_key: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
