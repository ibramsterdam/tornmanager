require "test_helper"

class UserApiCallsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bram)
    sign_in_as(@user)
  end

  test "should get index" do
    get user_api_calls_url
    assert_response :success
  end
end
