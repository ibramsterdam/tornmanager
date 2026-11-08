require "test_helper"

class Api::TmCompany::CompanyControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    stub_company_types
    @user = tracked_director
  end

  test "shows the report for the director's company" do
    captured_day

    post api_company_overview_path, headers: api_auth(@user), as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Test Oil Co", json.dig("company", "name")
    assert_equal 6, json["employees"].size
    assert json["advice"].any?
  end

  test "queues a capture when there is no data yet" do
    post api_company_overview_path, headers: api_auth(@user), as: :json

    assert_response :ok
    assert JSON.parse(response.body)["pending"]
    assert_enqueued_with(job: TmCompany::CaptureJob, args: [ @user.id ])
  end

  test "never shows another company" do
    captured_day(company_id: 999)

    post api_company_overview_path, headers: api_auth(@user), as: :json

    assert JSON.parse(response.body)["pending"]
  end

  test "returns history for charts" do
    post api_company_history_path, params: { days: 30 }, headers: api_auth(@user), as: :json

    assert_response :ok
    assert_equal 30, JSON.parse(response.body)["dates"].size
  end

  test "returns company news" do
    CompanyNewsEntry.create!(company_torn_id: 127301, news_id: "n1", occurred_at: 1.hour.ago, text: "Joe trained Employee1")
    CompanyNewsEntry.create!(company_torn_id: 999, news_id: "n2", occurred_at: 1.hour.ago, text: "Other company")

    post api_company_news_path, headers: api_auth(@user), as: :json

    assert_equal [ "n1" ], JSON.parse(response.body)["news"].map { |entry| entry["id"] }
  end

  test "does not refresh data captured in the last 15 minutes" do
    captured_day

    post api_company_refresh_path, headers: api_auth(@user), as: :json

    assert_not JSON.parse(response.body)["queued"]
    assert_no_enqueued_jobs only: TmCompany::CaptureJob
  end

  test "refreshes older data" do
    captured_day(captured_at: 1.hour.ago)

    post api_company_refresh_path, headers: api_auth(@user), as: :json

    assert JSON.parse(response.body)["queued"]
    assert_enqueued_with(job: TmCompany::CaptureJob, args: [ @user.id ])
  end

  test "requires a subscription" do
    @user.subscription.update!(expires_at: 1.day.ago)

    post api_company_overview_path, headers: api_auth(@user), as: :json

    assert_response :forbidden
    assert JSON.parse(response.body)["subscription_required"]
  end

  test "blocks a user whose access is turned off" do
    @user.update!(company_access_disabled: true)

    post api_company_overview_path, headers: api_auth(@user), as: :json

    assert_response :forbidden
  end

  test "asks to sign in again without a company key" do
    @user.company_api_key.destroy!

    post api_company_overview_path, headers: api_auth(@user), as: :json

    assert_response :unauthorized
    assert JSON.parse(response.body)["reauth"]
  end

  test "asks to sign in again when no longer the director" do
    @user.update!(company_director: false)

    post api_company_overview_path, headers: api_auth(@user), as: :json

    assert_response :unauthorized
  end

  test "blocks a banned user" do
    @user.update!(banned_until: 1.day.from_now, banned_reason: "Abuse")

    post api_company_overview_path, headers: api_auth(@user), as: :json

    assert_response :forbidden
    assert JSON.parse(response.body)["suspended"]
  end

  test "requires a session" do
    post api_company_overview_path, as: :json

    assert_response :unauthorized
  end
end
