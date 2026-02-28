require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bram)
    sign_in_as(@user)
  end

  test "should get settings index when authenticated" do
    get settings_path
    assert_response :success
    assert_select "h1", "Settings"
  end

  test "should redirect to login when not authenticated" do
    sign_out
    get settings_path
    assert_redirected_to new_session_path
  end

  test "index shows subscription status for subscribed users" do
    @user.update!(subscription_expires_at: 30.days.from_now)
    get settings_path
    assert_response :success
    assert_match /days remaining/, response.body
    assert_match /Active Subscriber/, response.body
  end

  test "index shows not subscribed state for non-subscribed users" do
    @user.update!(subscription_expires_at: nil)
    get settings_path
    assert_response :success
    assert_select ".subscription-badge-inactive", text: "Not Subscribed"
    assert_select ".subscription-inactive", /don't have an active subscription/
    assert_select ".subscription-active", count: 0
    assert_select ".subscription-days", count: 0
  end

  test "index shows not subscribed state for expired subscriptions" do
    @user.update!(subscription_expires_at: 1.day.ago)
    get settings_path
    assert_response :success
    assert_select ".subscription-badge-inactive", text: "Not Subscribed"
    assert_select ".subscription-inactive", /don't have an active subscription/
    assert_select ".subscription-active", count: 0
    assert_select ".subscription-days", count: 0
  end

  test "index calculates days remaining correctly" do
    @user.update!(subscription_expires_at: 42.days.from_now)
    get settings_path
    assert_response :success
    assert_match /42 days remaining/, response.body
  end

  test "index shows data counts" do
    @user.api_calls.create!(endpoint: "test", api_key: "test123", status: "success")

    get settings_path
    assert_response :success
    assert_select ".data-stats-value", text: @user.sessions.count.to_s
    assert_select ".data-stats-value", text: @user.api_calls.count.to_s
    assert_select ".data-stats-value", text: @user.sent_xanax_payments.count.to_s
    assert_select ".data-stats-value", text: @user.subscription_grants.count.to_s
  end

  test "purge_data deletes all user sessions" do
    initial_session_count = @user.sessions.count
    @user.sessions.create!
    @user.sessions.create!

    total_sessions = @user.sessions.count

    assert_difference "Session.count", -total_sessions do
      delete settings_purge_data_path
    end

    assert_equal 0, @user.sessions.count
  end

  test "purge_data deletes all api_calls" do
    initial_count = @user.api_calls.count
    call_1 = @user.api_calls.create!(endpoint: "test1", api_key: "key1", status: "success")
    call_2 = @user.api_calls.create!(endpoint: "test2", api_key: "key2", status: "success")

    expected_change = -(initial_count + 2)

    assert_difference "ApiCall.count", expected_change do
      delete settings_purge_data_path
    end

    assert_not ApiCall.exists?(call_1.id)
    assert_not ApiCall.exists?(call_2.id)
    assert_equal 0, @user.api_calls.count
  end

  test "purge_data clears api_key" do
    @user.update!(api_key: "test_key_123")

    delete settings_purge_data_path

    @user.reload
    assert_nil @user.api_key
  end

  test "purge_data preserves subscription" do
    expiration = 30.days.from_now
    @user.update!(subscription_expires_at: expiration)

    delete settings_purge_data_path

    @user.reload
    assert_equal expiration.to_i, @user.subscription_expires_at.to_i
  end

  test "purge_data preserves user record" do
    torn_id = @user.torn_id
    name = @user.name
    level = @user.level

    assert_no_difference "User.count" do
      delete settings_purge_data_path
    end

    user = User.find_by(torn_id: torn_id)
    assert_not_nil user
    assert_equal name, user.name
    assert_equal level, user.level
  end

  test "purge_data signs out user and redirects to root" do
    delete settings_purge_data_path

    assert_redirected_to root_path
    assert_not_nil flash[:notice]
    assert_match /data.*deleted/i, flash[:notice]
    assert_match /subscription.*preserved/i, flash[:notice]
  end

  test "refresh_subscription triggers XanaxPaymentsJob" do
    Daily::XanaxPaymentsJob.expects(:perform_now).once

    post settings_refresh_subscription_path

    assert_redirected_to settings_path
    assert_equal "Subscription status refreshed! Check your subscription details above.", flash[:notice]
  end

  test "refresh_subscription handles job failures gracefully" do
    Daily::XanaxPaymentsJob.stubs(:perform_now).raises(StandardError.new("API error"))

    post settings_refresh_subscription_path

    assert_redirected_to settings_path
    assert_not_nil flash[:alert]
    assert_match /failed/i, flash[:alert]
  end

  test "refresh_subscription logs errors on failure" do
    error = StandardError.new("Test error")
    Daily::XanaxPaymentsJob.stubs(:perform_now).raises(error)

    Rails.logger.expects(:error).with(regexp_matches(/Failed to refresh subscription/))

    post settings_refresh_subscription_path
  end

  test "refresh_subscription requires authentication" do
    sign_out

    post settings_refresh_subscription_path

    assert_redirected_to new_session_path
  end

  test "purge_data requires authentication" do
    sign_out

    delete settings_purge_data_path

    assert_redirected_to new_session_path
  end

  test "index displays subscription instructions in collapsible details" do
    get settings_path

    assert_response :success
    assert_select "details.subscribe-details" do
      assert_select "summary", text: "How to subscribe"
    end
    assert_match /Bram \[2728237\]/, response.body
    assert_match /1 week/, response.body
    assert_match /Xanax Payment/, response.body
    assert_match /Faction Sharing/, response.body
  end

  test "index renders API Key and Subscription in side-by-side grid" do
    get settings_path

    assert_response :success
    assert_select ".settings-top-grid" do
      assert_select ".api-key-card"
      assert_select ".subscription-card"
    end
  end

  test "refresh_subscription enforces cooldown period" do
    # First refresh should work
    Daily::XanaxPaymentsJob.expects(:perform_now).once
    post settings_refresh_subscription_path
    assert_redirected_to settings_path

    # Second refresh within 1 minute should be blocked
    Daily::XanaxPaymentsJob.expects(:perform_now).never
    post settings_refresh_subscription_path
    assert_redirected_to settings_path
    assert_match /wait.*seconds/i, flash[:alert]
  end

  test "index shows disabled button when cooldown is active" do
    # Trigger a refresh to start cooldown
    Daily::XanaxPaymentsJob.stubs(:perform_now)
    post settings_refresh_subscription_path

    # Check index shows disabled button
    get settings_path
    assert_response :success
    assert_match /Available in \d+ seconds/, response.body
  end

  test "index shows enabled button when no previous refresh" do
    get settings_path
    assert_response :success
    assert_match /Check for New Payments/, response.body
  end

  # ── update_api_key ──

  test "update_api_key with blank key returns error" do
    patch settings_update_api_key_path, params: { api_key: "" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_match /blank/, json["message"]
  end

  test "update_api_key with same key returns error" do
    @user.update!(api_key: "current_key_123")

    patch settings_update_api_key_path, params: { api_key: "current_key_123" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_match /already your current/, json["message"]
  end

  test "update_api_key rejects Full Access keys" do
    stub_key_info(type: "Full Access")

    patch settings_update_api_key_path, params: { api_key: "new_key_456" }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_match /Full Access.*not allowed/, json["message"]
  end

  test "update_api_key rejects key belonging to different user" do
    stub_key_info(type: "Limited Access")
    stub_profile(torn_id: 9999999) # different from @user.torn_id

    patch settings_update_api_key_path, params: { api_key: "new_key_456" }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_match /different user/, json["message"]
  end

  test "update_api_key succeeds with valid Limited Access key" do
    stub_key_info(type: "Limited Access")
    stub_profile(torn_id: @user.torn_id)

    patch settings_update_api_key_path, params: { api_key: "new_key_456" }, as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert_match /updated/, json["message"]
    assert_equal "Limited Access", json["access_type"]

    @user.reload
    assert_equal "new_key_456", @user.api_key
    assert_equal "Limited Access", @user.api_access_type
  end

  test "update_api_key handles invalid key from Torn API" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError)

    patch settings_update_api_key_path, params: { api_key: "bad_key" }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_match /Invalid API key/, json["message"]
  end

  test "update_api_key handles Torn API errors" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::ApiError.new("API is down"))

    patch settings_update_api_key_path, params: { api_key: "some_key" }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_match /Torn API error/, json["message"]
  end

  test "update_api_key handles unexpected errors" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(StandardError.new("boom"))

    patch settings_update_api_key_path, params: { api_key: "some_key" }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_match /Failed to update/, json["message"]
  end

  test "update_api_key requires authentication" do
    sign_out
    patch settings_update_api_key_path, params: { api_key: "key" }, as: :json
    assert_redirected_to new_session_path
  end

  # ── export_data ──

  test "export_data returns a JSON file download" do
    get settings_export_data_path

    assert_response :success
    assert_equal "application/json", response.content_type
    assert_match /attachment/, response.headers["Content-Disposition"]
    assert_match /tornmanager-data-#{@user.torn_id}/, response.headers["Content-Disposition"]
  end

  test "export_data includes user profile and api calls" do
    @user.api_calls.create!(endpoint: "/test", status: "success", api_key: "k")

    get settings_export_data_path

    data = JSON.parse(response.body)
    assert_equal @user.torn_id, data["user"]["torn_id"]
    assert_equal @user.name, data["user"]["name"]
    assert data["api_calls"].any? { |c| c["endpoint"] == "/test" }
  end

  test "export_data requires authentication" do
    sign_out
    get settings_export_data_path
    assert_redirected_to new_session_path
  end

  # ── api_key_card ──

  test "api_key_card renders successfully" do
    get settings_api_key_card_path
    assert_response :success
  end

  test "api_key_card requires authentication" do
    sign_out
    get settings_api_key_card_path
    assert_redirected_to new_session_path
  end

  private

  def stub_key_info(type:)
    mock = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 1, type: type, faction: false, company: false),
      user: TornApi::Key::Info::UserData.new(id: @user.torn_id, faction_id: nil, company_id: nil)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(mock)
  end

  def stub_profile(torn_id:)
    mock = TornApi::User::Profile::ProfileData.new(id: torn_id, name: "Test", level: 50, image: "https://example.com/img.jpg")
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(mock)
  end
end
