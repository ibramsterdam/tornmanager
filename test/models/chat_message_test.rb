require "test_helper"

class ChatMessageTest < ActiveSupport::TestCase
  setup do
    @room = ChatRoom.create!(name: "Test room", host_user: users(:bram), last_message_at: Time.current)
  end

  test "requires a body or an image" do
    message = @room.chat_messages.new(body: "")

    assert_not message.valid?
    assert_includes message.errors[:body], "can't be blank"
  end

  test "an attached image satisfies presence without a body" do
    message = @room.chat_messages.new(body: "")
    attach_sample(message)

    assert message.valid?
  end

  test "rejects an image over the size limit" do
    message = @room.chat_messages.new(body: "")
    attach_sample(message)
    message.image.blob.stubs(:byte_size).returns(ChatMessage::MAX_IMAGE_BYTES + 1)

    assert_not message.valid?
    assert_includes message.errors[:image], "is too large"
  end

  test "as_api_json exposes an image path only when an image is attached" do
    text_only = @room.chat_messages.create!(body: "hi")
    assert_nil text_only.as_api_json[:image_path]

    with_image = @room.chat_messages.new(body: "hi")
    attach_sample(with_image)
    with_image.save!
    assert with_image.as_api_json[:image_path].present?
  end

  private

  def attach_sample(message)
    message.image.attach(
      io: StringIO.new(png_bytes),
      filename: "sample.png",
      content_type: "image/png"
    )
  end

  def png_bytes
    Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMBAQDJ/pLvAAAAAElFTkSuQmCC")
  end
end
