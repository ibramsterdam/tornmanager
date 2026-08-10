class ChatRoom < ApplicationRecord
  MEMBER_LIMIT = 20
  PER_USER_LIMIT = 10
  EMPTY_RETENTION_DAYS = 7
  PUBLIC_MESSAGE_RETENTION = 24.hours

  ANON_ADJECTIVES = %w[
    Silent Crimson Shadow Golden Iron Swift Frost Ember Storm Lunar
    Rogue Velvet Onyx Scarlet Cobalt Phantom Rapid Quiet Masked Hidden
  ].freeze
  ANON_NOUNS = %w[
    Bandit Mobster Grifter Bootlegger Enforcer Racketeer Smuggler Outlaw Hustler Fixer
    Kingpin Gangster Bagman Forger Burglar Swindler Arsonist Rustler Pickpocket Mastermind
  ].freeze

  has_secure_token :invite_token, length: 24

  belongs_to :host_user, class_name: "User", optional: true
  has_many :chat_memberships, dependent: :delete_all
  has_many :users, through: :chat_memberships
  has_many :chat_messages, dependent: :destroy
  has_many :chat_suspensions, dependent: :delete_all

  validates :name, presence: true, length: { maximum: 40 }
  validates :kind, inclusion: { in: %w[private public] }

  scope :private_rooms, -> { where(kind: "private") }
  scope :public_rooms, -> { where(kind: "public") }
  # Empty (no members) for the retention window — the beginless range excludes
  # rooms whose emptied_at is nil (i.e. rooms that still have members).
  scope :abandoned, -> { private_rooms.where(emptied_at: ..EMPTY_RETENTION_DAYS.days.ago) }

  def public?
    kind == "public"
  end

  def host?(user)
    !public? && host_user_id == user&.id
  end

  def suspended?(user)
    chat_suspensions.exists?(user_id: user&.id)
  end

  def invite_url
    "https://www.torn.com/index.php#tmchat=#{invite_token}"
  end

  def info_for(user)
    host = host?(user)
    {
      id: id,
      name: name,
      kind: kind,
      encrypted: encrypted,
      host: host,
      suspended: suspended?(user),
      member_count: chat_memberships.count,
      invite_url: host ? invite_url : nil
    }
  end

  def self.random_anon_name
    "#{ANON_ADJECTIVES.sample} #{ANON_NOUNS.sample} #{rand(1..999)}"
  end

  def post_system_message(body)
    chat_messages.create!(body: body, system: true, sender_name: "", sender_torn_id: 0)
  end
end
