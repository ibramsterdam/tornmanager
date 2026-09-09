require "test_helper"

class Discord::WebhookTest < ActiveSupport::TestCase
  setup do
    @webhook = Discord::Webhook.new("https://discord.com/api/webhooks/1/token")
  end

  test "post returns the created message id" do
    response = stub(code: "200", body: { id: "987" }.to_json)
    Net::HTTP.expects(:start).returns(response)

    assert_equal "987", @webhook.post(content: "hello")
  end

  test "post returns nil on a failed request" do
    response = stub(code: "429", body: "rate limited")
    Net::HTTP.expects(:start).returns(response)

    assert_nil @webhook.post(content: "hello")
  end

  test "edit reports success" do
    response = stub(code: "200", body: "{}")
    Net::HTTP.expects(:start).returns(response)

    assert @webhook.edit("987", content: "updated")
  end

  test "does nothing without a url" do
    Net::HTTP.expects(:start).never

    blank = Discord::Webhook.new(nil)
    assert_not blank.configured?
    assert_nil blank.post(content: "hello")
    assert_nil blank.edit("987", content: "updated")
  end
end
