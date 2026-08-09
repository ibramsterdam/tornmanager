require "test_helper"

class Api::ChatRoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bram = users(:bram)
    @bert = users(:bert)
    Rails.cache.clear
  end

  test "creating a room returns the invite url to the host" do
    post api_chat_create_room_path, params: { api_key: @bram.api_key, name: "Hawaii squad" }, as: :json

    assert_response :created
    room = JSON.parse(response.body)["room"]
    assert_equal "Hawaii squad", room["name"]
    assert room["host"]
    assert_equal 1, room["member_count"]
    assert_match %r{https://www\.torn\.com/index\.php#tmchat=\w+}, room["invite_url"]
  end

  test "creating a room requires a name" do
    post api_chat_create_room_path, params: { api_key: @bram.api_key, name: "  " }, as: :json

    assert_response :unprocessable_entity
  end

  test "a user cannot create more rooms than the per-user limit" do
    ChatRoom::PER_USER_LIMIT.times do |i|
      post api_chat_create_room_path, params: { api_key: @bram.api_key, name: "Room #{i}" }, as: :json
      assert_response :created
    end

    post api_chat_create_room_path, params: { api_key: @bram.api_key, name: "One too many" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "You're already in #{ChatRoom::PER_USER_LIMIT} rooms. Leave one first.", JSON.parse(response.body)["error"]
  end

  test "a user cannot join more rooms than the per-user limit" do
    ChatRoom::PER_USER_LIMIT.times { |i| create_room(@bert, "Bert #{i}") }

    room = create_room(@bram, "Hawaii squad")

    post api_chat_join_path, params: { api_key: @bert.api_key, token: room.invite_token }, as: :json

    assert_response :unprocessable_entity
    assert_equal 1, room.chat_memberships.count
  end

  test "rejoining an existing room works even at the per-user limit" do
    rooms = ChatRoom::PER_USER_LIMIT.times.map { |i| create_room(@bert, "Bert #{i}") }

    post api_chat_join_path, params: { api_key: @bert.api_key, token: rooms.first.invite_token }, as: :json

    assert_response :ok
  end

  test "joining via invite token adds a membership and announces it" do
    room = create_room(@bram, "Hawaii squad")

    post api_chat_join_path, params: { api_key: @bert.api_key, token: room.invite_token }, as: :json

    assert_response :ok
    joined = JSON.parse(response.body)["room"]
    assert_equal 2, joined["member_count"]
    assert_not joined["host"]
    assert_nil joined["invite_url"]
    assert room.chat_messages.exists?(system: true, body: "#{@bert.name} joined.")
  end

  test "joining twice is idempotent" do
    room = create_room(@bram, "Hawaii squad")

    2.times do
      post api_chat_join_path, params: { api_key: @bert.api_key, token: room.invite_token }, as: :json
      assert_response :ok
    end

    assert_equal 2, room.chat_memberships.count
  end

  test "joining with an unknown token fails" do
    post api_chat_join_path, params: { api_key: @bert.api_key, token: "nope" }, as: :json

    assert_response :not_found
  end

  test "joining a full room fails" do
    room = create_room(@bram, "Hawaii squad")
    (ChatRoom::MEMBER_LIMIT - 1).times do |i|
      user = User.create!(torn_id: 900000 + i, name: "Filler#{i}", level: 1)
      room.chat_memberships.create!(user: user)
    end

    post api_chat_join_path, params: { api_key: @bert.api_key, token: room.invite_token }, as: :json

    assert_response :unprocessable_entity
    assert_equal "This room is full.", JSON.parse(response.body)["error"]
  end

  test "index lists only my rooms" do
    mine = create_room(@bram, "Mine")
    create_room(@bert, "Not mine")

    post api_chat_rooms_path, params: { api_key: @bram.api_key }, as: :json

    assert_response :ok
    rooms = JSON.parse(response.body)["rooms"]
    assert_equal [ mine.id ], rooms.map { |r| r["id"] }
  end

  test "leaving a room announces it and keeps the room alive for others" do
    room = create_room(@bram, "Hawaii squad")
    room.chat_memberships.create!(user: @bert)

    post api_chat_leave_path, params: { api_key: @bert.api_key, room_id: room.id }, as: :json

    assert_response :ok
    assert_not room.chat_memberships.exists?(user: @bert)
    assert room.chat_messages.exists?(system: true, body: "#{@bert.name} left.")
  end

  test "the last member leaving destroys the room" do
    room = create_room(@bram, "Hawaii squad")

    post api_chat_leave_path, params: { api_key: @bram.api_key, room_id: room.id }, as: :json

    assert_response :ok
    assert_not ChatRoom.exists?(room.id)
  end

  test "requires an api key" do
    post api_chat_rooms_path, params: {}, as: :json

    assert_response :bad_request
  end

  test "rejects unknown api keys" do
    post api_chat_rooms_path, params: { api_key: "nonexistent" }, as: :json

    assert_response :not_found
  end

  private

  def create_room(user, name)
    room = ChatRoom.create!(name: name, host_user: user, last_message_at: Time.current)
    room.chat_memberships.create!(user: user, host: true)
    room
  end
end
