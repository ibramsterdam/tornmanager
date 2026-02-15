require "test_helper"

class UserApiCallsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get user_api_calls_index_url
    assert_response :success
  end
end
