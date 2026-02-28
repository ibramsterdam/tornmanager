require "test_helper"

class PublicWarLobbyTest < ActiveSupport::TestCase
  # -- Validations --

  test "valid lobby saves successfully" do
    lobby = PublicWarLobby.new(
      faction_torn_id: 11111,
      faction_name: "Alpha",
      opponent_faction_name: "Bravo",
      created_by_name: "Someone",
      created_by_torn_id: 9999999
    )
    assert lobby.save
    assert lobby.slug.present?
  end

  test "requires faction_torn_id" do
    lobby = PublicWarLobby.new(
      faction_name: "Alpha",
      opponent_faction_name: "Bravo",
      created_by_name: "Someone",
      created_by_torn_id: 9999999
    )
    assert_not lobby.valid?
    assert lobby.errors[:faction_torn_id].any?
  end

  test "requires faction_name" do
    lobby = PublicWarLobby.new(
      faction_torn_id: 11111,
      opponent_faction_name: "Bravo",
      created_by_name: "Someone",
      created_by_torn_id: 9999999
    )
    assert_not lobby.valid?
    assert lobby.errors[:faction_name].any?
  end

  test "requires opponent_faction_name" do
    lobby = PublicWarLobby.new(
      faction_torn_id: 11111,
      faction_name: "Alpha",
      created_by_name: "Someone",
      created_by_torn_id: 9999999
    )
    assert_not lobby.valid?
    assert lobby.errors[:opponent_faction_name].any?
  end

  test "requires created_by_name" do
    lobby = PublicWarLobby.new(
      faction_torn_id: 11111,
      faction_name: "Alpha",
      opponent_faction_name: "Bravo",
      created_by_torn_id: 9999999
    )
    assert_not lobby.valid?
    assert lobby.errors[:created_by_name].any?
  end

  test "requires created_by_torn_id" do
    lobby = PublicWarLobby.new(
      faction_torn_id: 11111,
      faction_name: "Alpha",
      opponent_faction_name: "Bravo",
      created_by_name: "Someone"
    )
    assert_not lobby.valid?
    assert lobby.errors[:created_by_torn_id].any?
  end

  test "slug must be unique" do
    existing = public_war_lobbies(:open_lobby)
    lobby = PublicWarLobby.new(
      slug: existing.slug,
      faction_torn_id: 11111,
      faction_name: "Alpha",
      opponent_faction_name: "Bravo",
      created_by_name: "Someone",
      created_by_torn_id: 9999999
    )
    assert_not lobby.valid?
    assert lobby.errors[:slug].any?
  end

  # -- Slug generation --

  test "generates slug automatically on create" do
    lobby = PublicWarLobby.create!(
      faction_torn_id: 11111,
      faction_name: "Alpha",
      opponent_faction_name: "Bravo",
      created_by_name: "Someone",
      created_by_torn_id: 9999999
    )
    assert lobby.slug.present?
    assert_equal 8, lobby.slug.length
  end

  test "does not overwrite existing slug" do
    lobby = PublicWarLobby.new(
      slug: "custom99",
      faction_torn_id: 11111,
      faction_name: "Alpha",
      opponent_faction_name: "Bravo",
      created_by_name: "Someone",
      created_by_torn_id: 9999999
    )
    lobby.save!
    assert_equal "custom99", lobby.slug
  end

  # -- Lobby limit --

  test "enforces maximum lobby limit on create" do
    PublicWarLobby.delete_all

    PublicWarLobby::MAX_LOBBIES.times do |i|
      PublicWarLobby.create!(
        faction_torn_id: 10000 + i,
        faction_name: "Faction #{i}",
        opponent_faction_name: "Opponent #{i}",
        created_by_name: "Creator #{i}",
        created_by_torn_id: 1000000 + i
      )
    end

    lobby = PublicWarLobby.new(
      faction_torn_id: 99999,
      faction_name: "One Too Many",
      opponent_faction_name: "Opponent",
      created_by_name: "Creator",
      created_by_torn_id: 8888888
    )
    assert_not lobby.valid?
    assert lobby.errors[:base].any?
    assert_match(/Maximum/, lobby.errors[:base].first)
  end

  # -- to_param --

  test "to_param returns slug" do
    lobby = public_war_lobbies(:open_lobby)
    assert_equal lobby.slug, lobby.to_param
  end

  # -- Cache keys --

  test "war_cache_key uses lobby id" do
    lobby = public_war_lobbies(:open_lobby)
    assert_equal "public_war_lobby:#{lobby.id}:war_data", lobby.war_cache_key
  end

  test "api_key_cache_key uses lobby id" do
    lobby = public_war_lobbies(:open_lobby)
    assert_equal "public_war_lobby:#{lobby.id}:api_key", lobby.api_key_cache_key
  end

  # -- active? --

  test "active? returns true when API key is cached" do
    lobby = public_war_lobbies(:open_lobby)

    with_memory_cache do
      Rails.cache.write(lobby.api_key_cache_key, "some_key")
      assert lobby.active?
    end
  end

  test "active? returns false when no API key is cached" do
    lobby = public_war_lobbies(:open_lobby)

    with_memory_cache do
      assert_not lobby.active?
    end
  end

  # -- password_protected? --

  test "password_protected? returns true when password_digest is present" do
    lobby = public_war_lobbies(:locked_lobby)
    assert lobby.password_protected?
  end

  test "password_protected? returns false when password_digest is nil" do
    lobby = public_war_lobbies(:open_lobby)
    assert_not lobby.password_protected?
  end

  # -- war_name --

  test "war_name combines faction and opponent names" do
    lobby = public_war_lobbies(:open_lobby)
    assert_equal "Test Faction vs Enemy Faction", lobby.war_name
  end

  # -- terminate! --

  test "terminate! deletes cache entries and destroys the record" do
    lobby = public_war_lobbies(:open_lobby)

    with_memory_cache do
      Rails.cache.write(lobby.war_cache_key, { some: "data" })
      Rails.cache.write(lobby.api_key_cache_key, "api_key_value")

      lobby.terminate!

      assert_nil Rails.cache.read(lobby.war_cache_key)
      assert_nil Rails.cache.read(lobby.api_key_cache_key)
      assert_raises(ActiveRecord::RecordNotFound) { lobby.reload }
    end
  end

  # -- authenticate (has_secure_password) --

  test "locked lobby authenticates with correct password" do
    lobby = public_war_lobbies(:locked_lobby)
    assert lobby.authenticate("secret")
  end

  test "locked lobby rejects incorrect password" do
    lobby = public_war_lobbies(:locked_lobby)
    assert_not lobby.authenticate("wrong")
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
