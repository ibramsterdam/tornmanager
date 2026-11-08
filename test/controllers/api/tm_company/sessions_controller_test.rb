require "test_helper"

class Api::TmCompany::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @profile = TornApi::User::Profile::ProfileData.new(id: 8800001, name: "Joe", level: 93, image: "https://profileimages.torn.com/joe.png")
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(@profile)
  end

  test "signs in a director with a limited key and stores the key encrypted" do
    stub_key("Limited Access")
    stub_job(director_job)

    assert_difference "User.count", 1 do
      post api_company_session_path, params: { api_key: "LIMITED_KEY" }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    user = User.find_by!(torn_id: 8800001)
    assert_equal user.api_token, json["token"]
    assert_equal 127301, json.dig("company", "id")
    assert_equal "Crude Awakening", json.dig("company", "name")
    assert_equal 28, json.dig("company", "type_id")
    assert_equal 127301, user.company_id
    assert user.company_director?

    assert_equal "LIMITED_KEY", user.company_api_key.key
    stored = ApiKey.connection.select_value("SELECT key FROM api_keys WHERE id = #{user.company_api_key.id}")
    assert_not_equal "LIMITED_KEY", stored
    assert_nil user.torn_api_key
  end

  test "accepts a custom key with company access" do
    stub_key("Custom", company: true)
    stub_job(director_job)

    post api_company_session_path, params: { api_key: "CUSTOM_KEY" }, as: :json

    assert_response :ok
  end

  test "keeps the public recruiter key when a director signs in" do
    bram = users(:bram)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(
      TornApi::User::Profile::ProfileData.new(id: bram.torn_id, name: bram.name, level: bram.level, image: nil)
    )
    stub_key("Limited Access")
    stub_job(director_job)
    token = bram.api_token

    post api_company_session_path, params: { api_key: "COMPANY_KEY" }, as: :json

    assert_response :ok
    bram.reload
    assert_equal "ABCDEF", bram.torn_api_key.key
    assert_equal "COMPANY_KEY", bram.company_api_key.key
    assert_equal token, bram.api_token
  end

  [ "Public Only", "Full Access", "Minimal Access" ].each do |type|
    test "rejects a #{type} key" do
      stub_key(type)
      TornApi::User::Job.any_instance.expects(:fetch).never

      post api_company_session_path, params: { api_key: "KEY" }, as: :json

      assert_response :bad_request
      assert_match "Limited access key", JSON.parse(response.body)["error"]
    end
  end

  test "rejects a custom key without company access" do
    stub_key("Custom", company: false)

    post api_company_session_path, params: { api_key: "KEY" }, as: :json

    assert_response :bad_request
  end

  test "rejects an employee who is not the director" do
    stub_key("Limited Access")
    stub_job(director_job.with(position: "Driller"))

    assert_no_difference [ "User.count", "ApiKey.count" ] do
      post api_company_session_path, params: { api_key: "EMPLOYEE_KEY" }, as: :json
    end

    assert_response :bad_request
    assert_match "Only company directors", JSON.parse(response.body)["error"]
  end

  test "rejects a player without a company job" do
    stub_key("Limited Access")
    stub_job(TornApi::User::Job::JobData.new(type: "job", company_id: nil, company_type_id: nil, company_name: "Army", rating: nil, position: "Private"))

    post api_company_session_path, params: { api_key: "KEY" }, as: :json

    assert_response :bad_request
    assert_match "Only company directors", JSON.parse(response.body)["error"]
  end

  test "rejects an invalid key" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "Invalid API key")

    post api_company_session_path, params: { api_key: "BAD" }, as: :json

    assert_response :bad_request
    assert_equal "Invalid Torn API key", JSON.parse(response.body)["error"]
  end

  test "rejects a banned user" do
    User.create!(torn_id: 8800001, name: "Joe", level: 93, banned_until: 1.day.from_now, banned_reason: "Abuse")
    stub_key("Limited Access")
    stub_job(director_job)

    post api_company_session_path, params: { api_key: "LIMITED_KEY" }, as: :json

    assert_response :forbidden
    assert_nil User.find_by(torn_id: 8800001).company_api_key
  end

  test "rejects a user whose access is turned off" do
    User.create!(torn_id: 8800001, name: "Joe", level: 93, company_access_disabled: true)
    stub_key("Limited Access")
    stub_job(director_job)

    post api_company_session_path, params: { api_key: "LIMITED_KEY" }, as: :json

    assert_response :forbidden
    assert_nil User.find_by(torn_id: 8800001).company_api_key
  end

  test "requires a key" do
    post api_company_session_path, params: { api_key: " " }, as: :json

    assert_response :bad_request
  end

  private

  def stub_key(type, company: true)
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(
      TornApi::Key::Info::InfoData.new(
        access: TornApi::Key::Info::AccessData.new(level: 3, type: type, faction: true, company: company),
        user: TornApi::Key::Info::UserData.new(id: 8800001, faction_id: nil, company_id: 127301)
      )
    )
  end

  def stub_job(job)
    TornApi::User::Job.any_instance.stubs(:fetch).returns(job)
  end

  def director_job
    TornApi::User::Job::JobData.new(type: "company", company_id: 127301, company_type_id: 28, company_name: "Crude Awakening", rating: 7, position: "Director")
  end
end
