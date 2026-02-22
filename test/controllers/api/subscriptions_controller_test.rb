require "test_helper"

class Api::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bram = users(:bram)
    Rails.cache.clear
  end

  test "returns subscription status for valid api key" do
    @bram.update!(subscription_expires_at: 1.week.from_now)

    post api_subscription_path, params: { api_key: @bram.api_key }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json.dig("subscription", "active")
    assert_not_nil json.dig("subscription", "expires_at")
  end

  test "returns inactive subscription when expired" do
    @bram.update!(subscription_expires_at: 1.day.ago)

    post api_subscription_path, params: { api_key: @bram.api_key }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json.dig("subscription", "active")
  end

  test "returns inactive subscription when never subscribed" do
    @bram.update!(subscription_expires_at: nil)

    post api_subscription_path, params: { api_key: @bram.api_key }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json.dig("subscription", "active")
    assert_nil json.dig("subscription", "expires_at")
  end

  test "returns error when api key is blank" do
    post api_subscription_path, params: { api_key: "" }, as: :json

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "API key is required", json["error"]
  end

  test "returns error when api key is missing" do
    post api_subscription_path, params: {}, as: :json

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "API key is required", json["error"]
  end

  test "returns not found for unknown api key" do
    post api_subscription_path, params: { api_key: "nonexistent_key" }, as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal "Unknown API key. Please sign in first.", json["error"]
  end

  test "refresh triggers payment check and reloads user" do
    @bram.update!(subscription_expires_at: nil)
    Daily::XanaxPaymentsJob.expects(:perform_now).once

    post api_subscription_path, params: { api_key: @bram.api_key, refresh: "1" }, as: :json

    assert_response :ok
  end

  test "refresh is rate limited after first call" do
    with_memory_cache do
      Daily::XanaxPaymentsJob.stubs(:perform_now)

      post api_subscription_path, params: { api_key: @bram.api_key, refresh: "1" }, as: :json
      assert_response :ok

      post api_subscription_path, params: { api_key: @bram.api_key, refresh: "1" }, as: :json
      assert_response :too_many_requests
      json = JSON.parse(response.body)
      assert_match /Payment check was run recently/, json["error"]
    end
  end

  test "normal check without refresh is not rate limited" do
    with_memory_cache do
      Daily::XanaxPaymentsJob.stubs(:perform_now)

      # First call with refresh — triggers rate limit
      post api_subscription_path, params: { api_key: @bram.api_key, refresh: "1" }, as: :json
      assert_response :ok

      # Second call without refresh — not rate limited
      post api_subscription_path, params: { api_key: @bram.api_key }, as: :json
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
