require "test_helper"

class Api::RecruiterStatusControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @bram = users(:bram)
    grant_subscription(@bram, expires_at: 1.week.from_now)
  end

  test "requires an active subscription" do
    post api_recruiter_status_path, params: { company_ids: [ 91001 ] }, headers: api_auth(users(:bert)), as: :json

    assert_response :forbidden
  end

  test "returns cached statuses" do
    payload = [ { torn_id: 1234567, status: "Online" } ]
    Rails.cache.stubs(:read).with("recruiter:status:91001").returns(payload)

    post api_recruiter_status_path, params: { company_ids: [ 91001 ] }, headers: api_auth(@bram), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Online", json.dig("statuses", "91001", 0, "status")
    assert_empty json["pending"]
  end

  test "enqueues a refresh for uncached companies" do
    assert_enqueued_with(job: Recruiter::CompanyStatusJob, args: [ 91001 ]) do
      post api_recruiter_status_path, params: { company_ids: [ 91001, 91001, 0 ] }, headers: api_auth(@bram), as: :json
    end

    json = JSON.parse(response.body)
    assert_equal [ 91001 ], json["pending"]
    assert_empty json["statuses"]
  end

  test "refresh drops the cache and re-enqueues" do
    payload = [ { torn_id: 1234567, status: "Online" } ]
    Rails.cache.stubs(:read).with("recruiter:status:91001").returns(payload)
    Rails.cache.expects(:delete).with("recruiter:status:91001")

    assert_enqueued_with(job: Recruiter::CompanyStatusJob, args: [ 91001 ]) do
      post api_recruiter_status_path, params: { company_ids: [ 91001 ], refresh: true }, headers: api_auth(@bram), as: :json
    end

    json = JSON.parse(response.body)
    assert_equal [ 91001 ], json["pending"]
    assert_empty json["statuses"]
  end

  test "caps the companies per request" do
    post api_recruiter_status_path, params: { company_ids: (1..40).to_a }, headers: api_auth(@bram), as: :json

    assert_equal 30, JSON.parse(response.body)["pending"].size
  end
end
