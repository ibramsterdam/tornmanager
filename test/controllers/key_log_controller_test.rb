require "test_helper"

class KeyLogControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_api_key = "test_api_key_12345"
    @mock_key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(
        level: 2,
        type: "Limited Access",
        faction: true,
        company: false
      ),
      user: TornApi::Key::Info::UserData.new(
        id: 123,
        faction_id: 456,
        company_id: nil
      )
    )

    @mock_log_data = TornApi::Key::Log::LogData.new(
      log: [
        TornApi::Key::Log::LogEntry.new(
          timestamp: Time.now.to_i - 3600,
          type: "user",
          selections: "profile,stocks",
          id: 123,
          ip: "192.168.1.1",
          comment: "tmanager"
        ),
        TornApi::Key::Log::LogEntry.new(
          timestamp: Time.now.to_i - 7200,
          type: "key",
          selections: "info",
          id: nil,
          ip: "192.168.1.1",
          comment: "tmanager"
        )
      ],
      _metadata: nil
    )
  end

  test "index shows form" do
    get key_log_path

    assert_response :success
    assert_select "h1", "API Key Activity Log"
    assert_select "input[name='api_key']"
    assert_select "input[type='checkbox']", 2
  end

  test "show with blank key redirects with error" do
    post key_log_show_path, params: { api_key: "" }

    assert_response :success
    assert_select ".flash-alert", text: /Please provide an API key/
  end

  test "show with invalid key redirects with error" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError)

    post key_log_show_path, params: { api_key: "invalid_key" }

    assert_response :success
    assert_select ".flash-alert", text: /Invalid API key/
  end

  test "show with valid key displays log data" do
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(@mock_key_info)
    TornApi::Key::Log.any_instance.stubs(:fetch).returns(@mock_log_data)

    post key_log_show_path, params: { api_key: @valid_api_key }

    assert_response :success
    assert_select "h1", "API Key Activity Log"
    assert_select ".api-key-inline", text: @valid_api_key
    assert_select ".log-stat-card", 4 # Peak Usage, Total Requests, Unique IPs, API Categories
    assert_select ".log-table tbody tr", 2 # Two log entries
  end

  test "show squishes whitespace from api key" do
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(@mock_key_info)
    TornApi::Key::Log.any_instance.stubs(:fetch).returns(@mock_log_data)

    post key_log_show_path, params: { api_key: "  #{@valid_api_key}  " }

    assert_response :success
    assert_select ".api-key-inline", text: @valid_api_key
  end

  test "show handles API errors gracefully" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(StandardError.new("Connection error"))

    post key_log_show_path, params: { api_key: @valid_api_key }

    assert_response :success
    assert_select ".flash-alert", text: /Error fetching key log/
  end

  test "GET to show redirects to index" do
    get key_log_show_path

    assert_redirected_to key_log_path
  end

  test "index is accessible without authentication" do
    # Don't sign in
    get key_log_path

    assert_response :success
  end
end
