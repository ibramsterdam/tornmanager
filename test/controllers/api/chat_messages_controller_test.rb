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
    post api_chat_send_message_path, params: { api_key: @bram.api_key, room_id: @room.id, body: "wheels up in 5" }, as: :json

    assert_response :created
    sent = JSON.parse(response.body)["message"]
    assert_equal "wheels up in 5", sent["body"]
    assert_equal @bram.torn_id, sent["torn_id"]
    assert_equal @bram.name, sent["name"]
    assert_not sent["system"]

    post api_chat_messages_path, params: { api_key: @bert.api_key, room_id: @room.id, since_id: 0 }, as: :json

    assert_response :ok
    messages = JSON.parse(response.body)["messages"]
    assert_equal [ "wheels up in 5" ], messages.map { |m| m["body"] }

    post api_chat_messages_path, params: { api_key: @bert.api_key, room_id: @room.id, since_id: sent["id"] }, as: :json

    assert_empty JSON.parse(response.body)["messages"]
  end

  test "sending updates the room's last_message_at" do
    @room.update!(last_message_at: 2.days.ago)

    post api_chat_send_message_path, params: { api_key: @bram.api_key, room_id: @room.id, body: "ping" }, as: :json

    assert_response :created
    assert @room.reload.last_message_at > 1.minute.ago
  end

  test "rejects messages over the length limit" do
    post api_chat_send_message_path,
      params: { api_key: @bram.api_key, room_id: @room.id, body: "x" * (ChatMessage::MAX_LENGTH + 1) }, as: :json

    assert_response :unprocessable_entity
  end

  test "rejects blank messages" do
    post api_chat_send_message_path, params: { api_key: @bram.api_key, room_id: @room.id, body: "   " }, as: :json

    assert_response :unprocessable_entity
  end

  test "rate limits rapid sending" do
    with_memory_cache do
      post api_chat_send_message_path, params: { api_key: @bram.api_key, room_id: @room.id, body: "one" }, as: :json
      assert_response :created

      post api_chat_send_message_path, params: { api_key: @bram.api_key, room_id: @room.id, body: "two" }, as: :json
      assert_response :too_many_requests
    end
  end

  test "a suspended member is blocked from reading and sending" do
    @room.chat_suspensions.create!(user: @bert)

    post api_chat_messages_path, params: { api_key: @bert.api_key, room_id: @room.id, since_id: 0 }, as: :json
    assert_response :forbidden

    post api_chat_send_message_path, params: { api_key: @bert.api_key, room_id: @room.id, body: "let me back" }, as: :json
    assert_response :forbidden
  end

  test "non-members cannot read messages" do
    outsider = users(:kaneki)

    post api_chat_messages_path, params: { api_key: outsider.api_key, room_id: @room.id, since_id: 0 }, as: :json

    assert_response :not_found
  end

  test "non-members cannot send messages" do
    outsider = users(:kaneki)

    post api_chat_send_message_path, params: { api_key: outsider.api_key, room_id: @room.id, body: "hi" }, as: :json

    assert_response :not_found
  end

  test "messages in a public room hide the sender's torn id and use their alias" do
    lounge = ChatRoom.create!(name: "The Lounge", kind: "public", host_user: nil, last_message_at: Time.current)
    lounge.chat_memberships.create!(user: @bram)

    post api_chat_send_message_path, params: { api_key: @bram.api_key, room_id: lounge.id, body: "anyone selling xanax?" }, as: :json

    assert_response :created
    sent = JSON.parse(response.body)["message"]
    assert_equal @bram.reload.chat_anon_name, sent["name"]
    assert_not_equal @bram.name, sent["name"]
    assert_nil sent["torn_id"]
    assert sent["own"]

    stored = lounge.chat_messages.last
    assert_nil stored.sender_torn_id
    assert_equal @bram.id, stored.user_id
  end

  test "public room messages appear anonymous to other members" do
    lounge = ChatRoom.create!(name: "The Lounge", kind: "public", host_user: nil, last_message_at: Time.current)
    lounge.chat_memberships.create!(user: @bram)
    lounge.chat_memberships.create!(user: @bert)

    post api_chat_send_message_path, params: { api_key: @bram.api_key, room_id: lounge.id, body: "hey" }, as: :json

    post api_chat_messages_path, params: { api_key: @bert.api_key, room_id: lounge.id, since_id: 0 }, as: :json

    assert_response :ok
    message = JSON.parse(response.body)["messages"].first
    assert_equal @bram.reload.chat_anon_name, message["name"]
    assert_nil message["torn_id"]
    assert_not message["own"]
  end

  test "sending an image attaches it and returns an image path" do
    assert_difference -> { @room.chat_messages.count }, 1 do
      post api_chat_send_image_path,
        params: { api_key: @bram.api_key, room_id: @room.id, image: fixture_file_upload("sample.png", "image/png") }
    end

    assert_response :created
    sent = JSON.parse(response.body)["message"]
    assert sent["image_path"].present?
    assert @room.chat_messages.last.image.attached?
  end

  test "an image can carry a caption body" do
    post api_chat_send_image_path,
      params: { api_key: @bram.api_key, room_id: @room.id, body: "check this", image: fixture_file_upload("sample.png", "image/png") }

    assert_response :created
    assert_equal "check this", JSON.parse(response.body)["message"]["body"]
  end

  test "sending an image with no file is rejected" do
    post api_chat_send_image_path, params: { api_key: @bram.api_key, room_id: @room.id }

    assert_response :bad_request
  end

  test "a suspended member cannot send an image" do
    @room.chat_suspensions.create!(user: @bert)

    post api_chat_send_image_path,
      params: { api_key: @bert.api_key, room_id: @room.id, image: fixture_file_upload("sample.png", "image/png") }

    assert_response :forbidden
  end

  test "non-members cannot send an image" do
    outsider = users(:kaneki)

    post api_chat_send_image_path,
      params: { api_key: outsider.api_key, room_id: @room.id, image: fixture_file_upload("sample.png", "image/png") }

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
