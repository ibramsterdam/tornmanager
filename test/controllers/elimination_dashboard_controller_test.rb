require "test_helper"

class EliminationDashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.credentials.stubs(:dig)
      .with(:cia_bot, :admin_dashboard_password).returns("thecakeisalie")
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
    assert_select "h2", "Coming soon"
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
