require "test_helper"

class EliminationDashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.credentials.stubs(:dig)
      .with(:cia_bot, :admin_dashboard_password).returns("thecakeisalie")
    Rails.application.credentials.stubs(:dig)
      .with(:cia_bot, :bot_token).returns("bot_token")
  end

  test "shows the password form without a session" do
    get elimination_dashboard_path

    assert_response :success
    assert_select "h1", "Conspiracy Intelligence Agency"
    assert_select "input[type=password]"
  end

  test "correct password unlocks the dashboard" do
    post elimination_dashboard_login_path, params: { password: "thecakeisalie" }
    assert_redirected_to elimination_dashboard_path

    get elimination_dashboard_path
    assert_select "h2", "Tracker"
    assert_select "h2", "Discord delivery"
    assert_select "h2", "Alert rules"
  end

  test "start and stop polling from the dashboard" do
    post elimination_dashboard_login_path, params: { password: "thecakeisalie" }

    post elimination_dashboard_start_path
    assert EliminationSetting.current.polling_active?

    post elimination_dashboard_stop_path
    assert_not EliminationSetting.current.polling_active?
  end

  test "start is refused without a session" do
    post elimination_dashboard_start_path

    assert_redirected_to elimination_dashboard_path
    assert_not EliminationSetting.current.polling_active?
  end

  test "wrong password points to Bram" do
    post elimination_dashboard_login_path, params: { password: "thecakeisnotalie" }

    assert_response :unauthorized
    assert_select "a[href=?]", "https://www.torn.com/profiles.php?XID=2728237", text: "Bram [2728237]"
  end

  test "missing credential rejects every password" do
    Rails.application.credentials.stubs(:dig)
      .with(:cia_bot, :admin_dashboard_password).returns(nil)

    post elimination_dashboard_login_path, params: { password: "" }

    assert_response :unauthorized
  end

  test "logout locks the dashboard again" do
    post elimination_dashboard_login_path, params: { password: "thecakeisalie" }
    delete elimination_dashboard_logout_path

    get elimination_dashboard_path
    assert_select "input[type=password]"
  end
end
