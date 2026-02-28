class PublicWarLobby < ApplicationRecord
  MAX_LOBBIES = 10

  has_secure_password validations: false

  validates :slug, presence: true, uniqueness: true
  validates :faction_torn_id, presence: true
  validates :faction_name, presence: true
  validates :opponent_faction_name, presence: true
  validates :created_by_name, presence: true
  validates :created_by_torn_id, presence: true
  validate :lobby_limit, on: :create

  before_validation :generate_slug, on: :create

  def to_param
    slug
  end

  def war_cache_key
    "public_war_lobby:#{id}:war_data"
  end

  def api_key_cache_key
    "public_war_lobby:#{id}:api_key"
  end

  def active?
    Rails.cache.exist?(api_key_cache_key)
  end

  def password_protected?
    password_digest.present?
  end

  def war_name
    "#{faction_name} vs #{opponent_faction_name}"
  end

  def terminate!
    Rails.cache.delete(war_cache_key)
    Rails.cache.delete(api_key_cache_key)
    destroy!
  end

  private

  def generate_slug
    self.slug ||= SecureRandom.alphanumeric(8).downcase
  end

  def lobby_limit
    errors.add(:base, "Maximum number of public lobbies (#{MAX_LOBBIES}) reached") if PublicWarLobby.count >= MAX_LOBBIES
  end
end
