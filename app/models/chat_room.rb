class ChatRoom < ApplicationRecord
  MEMBER_LIMIT = 20
  HOSTED_LIMIT = 5
  IDLE_RETENTION_DAYS = 7

  has_secure_token :invite_token, length: 24

  belongs_to :host_user, class_name: "User"
  has_many :chat_memberships, dependent: :delete_all
  has_many :users, through: :chat_memberships
  has_many :chat_messages, dependent: :delete_all

  validates :name, presence: true, length: { maximum: 40 }

  scope :idle, -> { where(last_message_at: ...IDLE_RETENTION_DAYS.days.ago) }

  def invite_url
    "https://www.torn.com/index.php#tmchat=#{invite_token}"
  end

  def info_for(user)
    host = host_user_id == user.id
    {
      id: id,
      name: name,
      host: host,
      member_count: chat_memberships.count,
      invite_url: host ? invite_url : nil
    }
  end

  def post_system_message(body)
    chat_messages.create!(body: body, system: true, sender_name: "", sender_torn_id: 0)
  end
end
