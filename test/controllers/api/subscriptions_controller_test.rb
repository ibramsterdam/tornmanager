require "test_helper"

class Api::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bram = users(:bram)
    Rails.cache.clear
  end

  test "returns subscription status for valid api key" do
    grant_subscription(@bram, expires_at: 1.week.from_now)

    post api_subscription_path, headers: api_auth(@bram), as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.dig("subscription", "active")
    assert_not_nil json.dig("subscription", "expires_at")
  end

  test "returns inactive subscription when expired" do
    grant_subscription(@bram, expires_at: 1.day.ago)

    post api_subscription_path, headers: api_auth(@bram), as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json.dig("subscription", "active")
  end

  test "returns inactive subscription when never subscribed" do
    post api_subscription_path, headers: api_auth(@bram), as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json.dig("subscription", "active")
    assert_nil json.dig("subscription", "expires_at")
  end

  test "returns error when token is blank" do
    post api_subscription_path, headers: { "Authorization" => "Bearer " }, as: :json

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Session token is required. Please sign in again.", json["error"]
  end

  test "returns error when token is missing" do
    post api_subscription_path, params: {}, as: :json

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Session token is required. Please sign in again.", json["error"]
  end

  test "returns error for unknown token" do
    post api_subscription_path, headers: { "Authorization" => "Bearer nonexistent_token" }, as: :json

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Unknown session. Please sign in again.", json["error"]
  end

  test "refresh triggers payment check and reloads user" do
    Daily::XanaxPaymentsJob.expects(:perform_now).once

    post api_subscription_path, params: { refresh: "1" }, headers: api_auth(@bram), as: :json

    assert_response :ok
  end

  test "refresh is rate limited after first call" do
    with_memory_cache do
      Daily::XanaxPaymentsJob.stubs(:perform_now)

      post api_subscription_path, params: { refresh: "1" }, headers: api_auth(@bram), as: :json
      assert_response :ok

      post api_subscription_path, params: { refresh: "1" }, headers: api_auth(@bram), as: :json
      assert_response :too_many_requests
      json = JSON.parse(response.body)
      assert_match /Payment check was run recently/, json["error"]
    end
  end

  test "normal check without refresh is not rate limited" do
    with_memory_cache do
      Daily::XanaxPaymentsJob.stubs(:perform_now)

      # First call with refresh — triggers rate limit
      post api_subscription_path, params: { refresh: "1" }, headers: api_auth(@bram), as: :json
      assert_response :ok

      # Second call without refresh — not rate limited
      post api_subscription_path, headers: api_auth(@bram), as: :json
      assert_response :ok
    end
  end

  private

  def with_memory_cache(&block)
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end
end
