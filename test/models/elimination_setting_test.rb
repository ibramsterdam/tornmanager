require "test_helper"

class EliminationSettingTest < ActiveSupport::TestCase
  test "current creates a singleton row with defaults" do
    setting = EliminationSetting.current

    assert setting.persisted?
    assert_equal "Conspiracy Theorists", setting.team_name
    assert_equal 2, setting.poll_interval_seconds
    assert_equal 10, setting.push_window_seconds
    assert_equal 10, setting.push_ticket_threshold
    assert_not setting.polling_active?
    assert_same setting.id, EliminationSetting.current.id
  end

  test "life ticks activate from the configured moment" do
    setting = EliminationSetting.current
    setting.update!(life_ticks_from: Time.utc(2026, 9, 11, 12))

    assert_not setting.life_ticks_active?(Time.utc(2026, 9, 11, 11, 59))
    assert setting.life_ticks_active?(Time.utc(2026, 9, 11, 12))
  end

  test "polling_api_key falls back to the admin key" do
    setting = EliminationSetting.current
    AdminCredentials.stubs(:api_key).returns("admin_key")

    assert_equal "admin_key", setting.polling_api_key

    setting.update!(api_key: "dedicated_key")
    assert_equal "dedicated_key", setting.polling_api_key
  end
end
