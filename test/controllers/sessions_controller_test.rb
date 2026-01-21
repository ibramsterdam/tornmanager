require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.take
    @mock_profile = { "id" => 123, "name" => "Bram" }
  end

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
