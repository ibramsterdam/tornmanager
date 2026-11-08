require "test_helper"

class Api::TmCompany::KeysControllerTest < ActionDispatch::IntegrationTest
  test "removes the company key and keeps the other keys" do
    bram = users(:bram)
    bram.set_company_api_key!("COMPANY_KEY", "Limited Access")

    post api_company_revoke_key_path, headers: api_auth(bram), as: :json

    assert_response :no_content
    assert_nil bram.reload.company_api_key
    assert_equal "ABCDEF", bram.torn_api_key.key
  end

  test "requires a session" do
    post api_company_revoke_key_path, as: :json

    assert_response :unauthorized
  end
end
