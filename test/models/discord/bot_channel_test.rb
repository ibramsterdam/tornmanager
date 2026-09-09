require "test_helper"

class Discord::BotChannelTest < ActiveSupport::TestCase
  setup do
    @channel = Discord::BotChannel.new("bot_token", "1234567890")
  end

  test "post returns the created message id" do
    response = stub(code: "200", body: { id: "987" }.to_json)
    Net::HTTP.expects(:start).returns(response)

    assert_equal "987", @channel.post(content: "hello")
  end

  test "post returns nil on a failed request" do
    response = stub(code: "403", body: "missing access")
    Net::HTTP.expects(:start).returns(response)

    assert_nil @channel.post(content: "hello")
  end

  test "edit reports success" do
    response = stub(code: "200", body: "{}")
    Net::HTTP.expects(:start).returns(response)

    assert @channel.edit("987", content: "updated")
  end

  test "does nothing without a token or channel" do
    Net::HTTP.expects(:start).never

    assert_nil Discord::BotChannel.new(nil, "123").post(content: "hello")
    assert_nil Discord::BotChannel.new("token", nil).post(content: "hello")
  end
end
