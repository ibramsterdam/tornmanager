require "test_helper"

class TornApi::User::LastActionTest < ActiveSupport::TestCase
  test "reads the last action from the profile" do
    service = TornApi::User::LastAction.new("test_key", 3152867)
    service.expects(:get).with("v2/user/3152867/profile", { striptags: true, comment: "tmrecruiter" }).returns(
      "profile" => { "id" => 3152867, "name" => "Boss", "level" => 70, "last_action" => { "status" => "Offline", "timestamp" => 1_790_000_000, "relative" => "40 days ago" } }
    )

    result = service.fetch

    assert_equal 3152867, result.torn_id
    assert_equal "Boss", result.name
    assert_equal 70, result.level
    assert_equal Time.zone.at(1_790_000_000), result.last_action_at
  end

  test "raises when no profile comes back" do
    service = TornApi::User::LastAction.new("test_key", 1)
    service.expects(:get).returns({})

    assert_raises(TornApi::ApiError) { service.fetch }
  end
end
