require "test_helper"

class TornApi::User::DiscordTest < ActiveSupport::TestCase
  setup do
    @api_key = "test_key"
  end

  test "fetches discord data for a user by discord id" do
    response = {
      "discord" => {
        "discord_id" => "123456789",
        "user_id" => 2728237
      }
    }

    service = TornApi::User::Discord.new(@api_key, "123456789")
    service.expects(:get).with("v2/user/123456789/discord").returns(response)

    result = service.fetch
    assert_equal "123456789", result.discord_id
    assert_equal 2728237, result.user_id
  end

  test "returns nil when user not found" do
    service = TornApi::User::Discord.new(@api_key, "999999999")
    service.expects(:get).raises(TornApi::NotFoundError, "not found")

    assert_nil service.fetch
  end

  test "returns nil when discord not linked" do
    response = {
      "discord" => {
        "discord_id" => nil,
        "user_id" => nil
      }
    }

    service = TornApi::User::Discord.new(@api_key, "123456789")
    service.expects(:get).returns(response)

    assert_nil service.fetch
  end
end
