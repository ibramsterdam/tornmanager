class ChatMessage < ApplicationRecord
  MAX_LENGTH = 2000
  MAX_IMAGE_BYTES = 6.megabytes

  belongs_to :chat_room
  belongs_to :user, optional: true
  has_one_attached :image

  validates :body, length: { maximum: MAX_LENGTH }
  validate :body_or_image_present
  validate :image_within_size_limit

  after_create_commit { chat_room.update_column(:last_message_at, created_at) }

  def as_api_json
    json = {
      id: id,
      torn_id: sender_torn_id,
      name: sender_name,
      body: body,
      system: system,
      at: created_at.iso8601
    }
    json[:has_image] = true if image.attached?
    json
  end

  private

  def body_or_image_present
    errors.add(:body, "can't be blank") if body.blank? && !image.attached?
  end

  def image_within_size_limit
    return unless image.attached?
    errors.add(:image, "is too large") if image.blob.byte_size > MAX_IMAGE_BYTES
  end
end
