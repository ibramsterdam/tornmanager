class ChatMessage < ApplicationRecord
  MAX_LENGTH = 300

  belongs_to :chat_room
  belongs_to :user, optional: true

  validates :body, presence: true, length: { maximum: MAX_LENGTH }

  after_create_commit { chat_room.update_column(:last_message_at, created_at) }

  def as_api_json
    {
      id: id,
      torn_id: sender_torn_id,
      name: sender_name,
      body: body,
      system: system,
      at: created_at.iso8601
    }
  end
end
