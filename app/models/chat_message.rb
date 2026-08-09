class ChatMessage < ApplicationRecord
  # Plaintext is capped at ~300 chars client-side; end-to-end encrypted bodies
  # arrive as base64 ciphertext, which inflates length, so the stored limit is
  # larger and serves only as an abuse ceiling.
  MAX_LENGTH = 2000

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
