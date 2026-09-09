require "test_helper"

class Admin::EliminationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:bram)
    sign_in_as(@admin)
  end

  test "shows the eliminations page" do
    get admin_eliminations_path

    assert_response :success
    assert_select "h1", "Conspiracy Intelligence Agency"
  end

  test "updates settings" do
    patch admin_eliminations_path, params: {
      elimination_setting: { push_ticket_threshold: 25, push_window_seconds: 15 }
    }

    assert_redirected_to admin_eliminations_path
    setting = EliminationSetting.current
    assert_equal 25, setting.push_ticket_threshold
    assert_equal 15, setting.push_window_seconds
  end

  test "rejects invalid settings" do
    patch admin_eliminations_path, params: {
      elimination_setting: { push_ticket_threshold: 0 }
    }

    assert_response :unprocessable_entity
  end

  test "starts and stops polling" do
    post start_admin_eliminations_path
    assert EliminationSetting.current.polling_active?

    post stop_admin_eliminations_path
    assert_not EliminationSetting.current.polling_active?
  end

  test "sends a test notification" do
    Elimination::Demo.any_instance.expects(:send!).with("standings")

    post test_admin_eliminations_path(kind: "standings")

    assert_redirected_to admin_eliminations_path
  end

  test "rejects unknown test kinds" do
    Elimination::Demo.any_instance.expects(:send!).never

    post test_admin_eliminations_path(kind: "everything")

    assert_redirected_to admin_eliminations_path
  end

  test "denies non-admins" do
    sign_in_as(users(:bert))

    get admin_eliminations_path
    assert_redirected_to root_path
  end
end
