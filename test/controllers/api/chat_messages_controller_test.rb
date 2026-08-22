require "test_helper"

class Api::ChatMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bram = users(:bram)
    @bert = users(:bert)
    Rails.cache.clear

    @room = ChatRoom.create!(name: "Hawaii squad", host_user: @bram, last_message_at: Time.current)
    @room.chat_memberships.create!(user: @bram, host: true)
    @room.chat_memberships.create!(user: @bert)
  end

  test "sending a message returns it and fetching with since_id picks it up" do
    post api_chat_send_message_path, params: { room_id: @room.id, body: "wheels up in 5" }, headers: api_auth(@bram), as: :json

    assert_response :created
    sent = JSON.parse(response.body)["message"]
    assert_equal "wheels up in 5", sent["body"]
    assert_equal @bram.torn_id, sent["torn_id"]
    assert_equal @bram.name, sent["name"]
    assert_not sent["system"]

    post api_chat_messages_path, params: { room_id: @room.id, since_id: 0 }, headers: api_auth(@bert), as: :json

    assert_response :ok
    messages = JSON.parse(response.body)["messages"]
    assert_equal [ "wheels up in 5" ], messages.map { |m| m["body"] }

    post api_chat_messages_path, params: { room_id: @room.id, since_id: sent["id"] }, headers: api_auth(@bert), as: :json

    assert_empty JSON.parse(response.body)["messages"]
  end

  test "sending updates the room's last_message_at" do
    @room.update!(last_message_at: 2.days.ago)

    post api_chat_send_message_path, params: { room_id: @room.id, body: "ping" }, headers: api_auth(@bram), as: :json

    assert_response :created
    assert @room.reload.last_message_at > 1.minute.ago
  end

  test "rejects messages over the length limit" do
    post api_chat_send_message_path,
      params: { room_id: @room.id, body: "x" * (ChatMessage::MAX_LENGTH + 1) }, headers: api_auth(@bram), as: :json

    assert_response :unprocessable_entity
  end

  test "rejects blank messages" do
    post api_chat_send_message_path, params: { room_id: @room.id, body: "   " }, headers: api_auth(@bram), as: :json

    assert_response :unprocessable_entity
  end

  test "rate limits rapid sending" do
    with_memory_cache do
      post api_chat_send_message_path, params: { room_id: @room.id, body: "one" }, headers: api_auth(@bram), as: :json
      assert_response :created

      post api_chat_send_message_path, params: { room_id: @room.id, body: "two" }, headers: api_auth(@bram), as: :json
      assert_response :too_many_requests
    end
  end

  test "a suspended member is blocked from reading and sending" do
    @room.chat_suspensions.create!(user: @bert)

    post api_chat_messages_path, params: { room_id: @room.id, since_id: 0 }, headers: api_auth(@bert), as: :json
    assert_response :forbidden

    post api_chat_send_message_path, params: { room_id: @room.id, body: "let me back" }, headers: api_auth(@bert), as: :json
    assert_response :forbidden
  end

  test "non-members cannot read messages" do
    outsider = users(:kaneki)

    post api_chat_messages_path, params: { room_id: @room.id, since_id: 0 }, headers: api_auth(outsider), as: :json

    assert_response :not_found
  end

  test "non-members cannot send messages" do
    outsider = users(:kaneki)

    post api_chat_send_message_path, params: { room_id: @room.id, body: "hi" }, headers: api_auth(outsider), as: :json

    assert_response :not_found
  end

  test "messages in an anonymous public room hide the sender's torn id and use their alias" do
    den = ChatRoom.create!(name: "The Muggers Den", kind: "public", anonymous: true, host_user: nil, last_message_at: Time.current)
    den.chat_memberships.create!(user: @bert)

    post api_chat_send_message_path, params: { room_id: den.id, body: "anyone selling xanax?" }, headers: api_auth(@bert), as: :json

    assert_response :created
    sent = JSON.parse(response.body)["message"]
    assert_equal @bert.reload.chat_anon_name, sent["name"]
    assert_not_equal @bert.name, sent["name"]
    assert_nil sent["torn_id"]
    assert sent["own"]

    stored = den.chat_messages.last
    assert_nil stored.sender_torn_id
    assert_equal @bert.id, stored.user_id
  end

  test "anonymous public room messages appear anonymous to other members" do
    den = ChatRoom.create!(name: "The Muggers Den", kind: "public", anonymous: true, host_user: nil, last_message_at: Time.current)
    den.chat_memberships.create!(user: @bram)
    den.chat_memberships.create!(user: @bert)

    post api_chat_send_message_path, params: { room_id: den.id, body: "hey" }, headers: api_auth(@bert), as: :json

    post api_chat_messages_path, params: { room_id: den.id, since_id: 0 }, headers: api_auth(@bram), as: :json

    assert_response :ok
    message = JSON.parse(response.body)["messages"].first
    assert_equal @bert.reload.chat_anon_name, message["name"]
    assert_nil message["torn_id"]
    assert_not message["own"]
  end

  test "admin messages stay public even in an anonymous room and carry the admin flag" do
    den = ChatRoom.create!(name: "The Muggers Den", kind: "public", anonymous: true, host_user: nil, last_message_at: Time.current)
    den.chat_memberships.create!(user: @bram)

    post api_chat_send_message_path, params: { room_id: den.id, body: "final warning" }, headers: api_auth(@bram), as: :json

    assert_response :created
    sent = JSON.parse(response.body)["message"]
    assert_equal @bram.name, sent["name"]
    assert_equal @bram.torn_id, sent["torn_id"]
    assert sent["admin"]
  end

  test "non-admin messages carry no admin flag" do
    post api_chat_send_message_path, params: { room_id: @room.id, body: "hello" }, headers: api_auth(@bert), as: :json

    assert_response :created
    assert_nil JSON.parse(response.body)["message"]["admin"]
  end

  test "messages in a named public room carry the sender's real name and torn id" do
    lounge = ChatRoom.create!(name: "The Lounge", kind: "public", anonymous: false, host_user: nil, last_message_at: Time.current)
    lounge.chat_memberships.create!(user: @bram)

    post api_chat_send_message_path, params: { room_id: lounge.id, body: "evening all" }, headers: api_auth(@bram), as: :json

    assert_response :created
    sent = JSON.parse(response.body)["message"]
    assert_equal @bram.name, sent["name"]
    assert_equal @bram.torn_id, sent["torn_id"]

    stored = lounge.chat_messages.last
    assert_equal @bram.torn_id, stored.sender_torn_id
  end

  test "sending an image attaches it and flags the message as carrying one" do
    assert_difference -> { @room.chat_messages.count }, 1 do
      post api_chat_send_image_path,
        params: { room_id: @room.id, image: fixture_file_upload("sample.png", "image/png") }, headers: api_auth(@bram)
    end

    assert_response :created
    sent = JSON.parse(response.body)["message"]
    assert sent["has_image"]
    assert @room.chat_messages.last.image.attached?
  end

  test "sending an image as base64 attaches it" do
    payload = Base64.strict_encode64(file_fixture("sample.png").binread)

    assert_difference -> { @room.chat_messages.count }, 1 do
      post api_chat_send_image_path, params: { room_id: @room.id, image_base64: payload }, headers: api_auth(@bram), as: :json
    end

    assert_response :created
    assert JSON.parse(response.body)["message"]["has_image"]
  end

  test "the image endpoint returns the attachment bytes as base64 to a member" do
    original = file_fixture("sample.png").binread
    post api_chat_send_image_path,
      params: { room_id: @room.id, image_base64: Base64.strict_encode64(original) }, headers: api_auth(@bram), as: :json
    message_id = JSON.parse(response.body)["message"]["id"]

    post api_chat_image_path, params: { room_id: @room.id, message_id: message_id }, headers: api_auth(@bert), as: :json

    assert_response :ok
    assert_equal original, Base64.strict_decode64(JSON.parse(response.body)["data"])
  end

  test "a suspended member cannot download an image" do
    post api_chat_send_image_path,
      params: { room_id: @room.id, image_base64: Base64.strict_encode64(file_fixture("sample.png").binread) }, headers: api_auth(@bram), as: :json
    message_id = JSON.parse(response.body)["message"]["id"]
    @room.chat_suspensions.create!(user: @bert)

    post api_chat_image_path, params: { room_id: @room.id, message_id: message_id }, headers: api_auth(@bert), as: :json

    assert_response :forbidden
  end

  test "non-members cannot download an image" do
    post api_chat_send_image_path,
      params: { room_id: @room.id, image_base64: Base64.strict_encode64(file_fixture("sample.png").binread) }, headers: api_auth(@bram), as: :json
    message_id = JSON.parse(response.body)["message"]["id"]

    post api_chat_image_path, params: { room_id: @room.id, message_id: message_id }, headers: api_auth(users(:kaneki)), as: :json

    assert_response :not_found
  end

  test "an image can carry a caption body" do
    post api_chat_send_image_path,
      params: { room_id: @room.id, body: "check this", image: fixture_file_upload("sample.png", "image/png") }, headers: api_auth(@bram)

    assert_response :created
    assert_equal "check this", JSON.parse(response.body)["message"]["body"]
  end

  test "sending an image with no file is rejected" do
    post api_chat_send_image_path, params: { room_id: @room.id }, headers: api_auth(@bram)

    assert_response :bad_request
  end

  test "a suspended member cannot send an image" do
    @room.chat_suspensions.create!(user: @bert)

    post api_chat_send_image_path,
      params: { room_id: @room.id, image: fixture_file_upload("sample.png", "image/png") }, headers: api_auth(@bert)

    assert_response :forbidden
  end

  test "non-members cannot send an image" do
    outsider = users(:kaneki)

    post api_chat_send_image_path,
      params: { room_id: @room.id, image: fixture_file_upload("sample.png", "image/png") }, headers: api_auth(outsider)

    assert_response :not_found
  end

  private

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end
end
