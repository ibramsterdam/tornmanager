require "test_helper"

class Api::RecruiterKeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bram = users(:bram)
    grant_subscription(@bram, expires_at: 1.week.from_now)
  end

  test "requires an active subscription" do
    post api_recruiter_submit_key_path, params: { key: "x" }, headers: api_auth(users(:bert)), as: :json

    assert_response :forbidden
  end

  test "creates the owner and pool key from a submitted public key" do
    stub_key_lookup(torn_id: 8888001, name: "Friend", level: 40)

    assert_difference "User.count", 1 do
      post api_recruiter_submit_key_path, params: { key: "FRIEND_KEY" }, headers: api_auth(@bram), as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)["key"]
    assert_equal "Friend", json["owner_name"]
    assert_not json["mine"]

    owner = User.find_by(torn_id: 8888001)
    record = owner.torn_api_key
    assert record.recruiter_fetch_allowed
    assert_equal @bram, record.submitted_by
    assert_equal "FRIEND_KEY", record.key
  end

  test "rejects a key whose owner is already in the pool" do
    stub_key_lookup(torn_id: 8888001, name: "Friend", level: 40)
    post api_recruiter_submit_key_path, params: { key: "FRIEND_KEY" }, headers: api_auth(@bram), as: :json

    post api_recruiter_submit_key_path, params: { key: "FRIEND_KEY_2" }, headers: api_auth(@bram), as: :json

    assert_response :conflict
  end

  test "rejects non public keys" do
    stub_key_lookup(torn_id: 8888001, name: "Friend", level: 40, access_type: "Limited Access")

    post api_recruiter_submit_key_path, params: { key: "LIMITED" }, headers: api_auth(@bram), as: :json

    assert_response :bad_request
    assert_match "Only Public access keys", JSON.parse(response.body)["error"]
  end

  test "rejects invalid keys" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "Invalid key")

    post api_recruiter_submit_key_path, params: { key: "BAD" }, headers: api_auth(@bram), as: :json

    assert_response :bad_request
  end

  test "flips the flag when the owner already has a stored key" do
    stub_key_lookup(torn_id: @bram.torn_id, name: @bram.name, level: @bram.level)

    assert_no_difference "ApiKey.count" do
      post api_recruiter_submit_key_path, params: { key: "SOME_PUBLIC_KEY" }, headers: api_auth(@bram), as: :json
    end

    assert_response :created
    assert JSON.parse(response.body).dig("key", "mine")
    assert api_keys(:bram_personal_key).reload.recruiter_fetch_allowed
  end

  test "lists contributed and own pool keys" do
    api_keys(:bram_personal_key).update!(recruiter_fetch_allowed: true)

    post api_recruiter_keys_path, params: {}, headers: api_auth(@bram), as: :json

    assert_response :success
    json = JSON.parse(response.body)["keys"]
    assert_equal [ @bram.torn_id ], json.map { |key| key["owner_torn_id"] }
    assert json.first["mine"]
  end

  test "revokes a pool key without deleting it" do
    record = api_keys(:bram_personal_key)
    record.update!(recruiter_fetch_allowed: true)

    post api_recruiter_revoke_key_path, params: { torn_id: @bram.torn_id }, headers: api_auth(@bram), as: :json

    assert_response :no_content
    assert_not record.reload.recruiter_fetch_allowed
    assert ApiKey.exists?(record.id)
  end

  test "revoke works without an active subscription" do
    bert = users(:bert)
    bert_key = api_keys(:bert_personal_key)
    bert_key.update!(recruiter_fetch_allowed: true)

    post api_recruiter_revoke_key_path, params: { torn_id: bert.torn_id }, headers: api_auth(bert), as: :json

    assert_response :no_content
    assert_not bert_key.reload.recruiter_fetch_allowed
  end

  test "revoke returns not found for keys outside your pool" do
    post api_recruiter_revoke_key_path, params: { torn_id: 999 }, headers: api_auth(@bram), as: :json

    assert_response :not_found
  end

  private

  def stub_key_lookup(torn_id:, name:, level:, access_type: "Public Only")
    info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 1, type: access_type, faction: false, company: false),
      user: TornApi::Key::Info::UserData.new(id: torn_id, faction_id: nil, company_id: nil)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(info)
    basic = TornApi::User::Basic::BasicData.new(id: torn_id, name: name, level: level, gender: "Male", status: nil)
    TornApi::User::Basic.any_instance.stubs(:fetch).returns(basic)
  end
end
