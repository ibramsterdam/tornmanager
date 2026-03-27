require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  setup do
    @faction = factions(:with_api_key)
    @faction.api_keys.destroy_all
  end

  test "belongs to faction" do
    key = ApiKey::Torn.new(faction: @faction, key: "abc123")
    assert_equal @faction, key.faction
  end

  test "validates presence of key" do
    key = ApiKey::Torn.new(faction: @faction)
    assert_not key.valid?
    assert_includes key.errors[:key], "can't be blank"
  end

  test "validates uniqueness of type per faction" do
    ApiKey::Torn.create!(faction: @faction, key: "key1")
    duplicate = ApiKey::Torn.new(faction: @faction, key: "key2")
    assert_not duplicate.valid?
  end

  test "allows same type across different factions" do
    other_faction = factions(:without_api_key)
    other_faction.api_keys.destroy_all
    ApiKey::Torn.create!(faction: @faction, key: "key1")
    other = ApiKey::Torn.new(faction: other_faction, key: "key2")
    assert other.valid?
  end

  test "allows torn and tornstats on same faction" do
    ApiKey::Torn.create!(faction: @faction, key: "torn_key")
    ts = ApiKey::Tornstats.new(faction: @faction, key: "ts_key")
    assert ts.valid?
  end

  test "STI returns correct subclass for Torn" do
    ApiKey::Torn.create!(faction: @faction, key: "torn_key")
    assert_instance_of ApiKey::Torn, @faction.torn_api_key
  end

  test "STI returns correct subclass for Tornstats" do
    ApiKey::Tornstats.create!(faction: @faction, key: "ts_key")
    assert_instance_of ApiKey::Tornstats, @faction.tornstats_api_key
  end

  test "faction_access? returns true when set" do
    key = ApiKey::Torn.new(faction_access: true)
    assert key.faction_access?
  end

  test "faction_access? returns false by default" do
    key = ApiKey::Torn.new
    assert_not key.faction_access?
  end
end

class FactionApiKeyIntegrationTest < ActiveSupport::TestCase
  setup do
    @faction = factions(:with_api_key)
    @faction.api_keys.destroy_all
  end

  test "faction.torn_api_key returns the record" do
    ApiKey::Torn.create!(faction: @faction, key: "my_torn_key")
    record = @faction.reload.torn_api_key
    assert_instance_of ApiKey::Torn, record
    assert_equal "my_torn_key", record.key
  end

  test "faction.torn_api_key returns nil when no torn key" do
    assert_nil @faction.torn_api_key
  end

  test "faction.tornstats_api_key returns the record" do
    ApiKey::Tornstats.create!(faction: @faction, key: "my_ts_key")
    record = @faction.reload.tornstats_api_key
    assert_instance_of ApiKey::Tornstats, record
    assert_equal "my_ts_key", record.key
  end

  test "destroying api keys via faction association" do
    api_key = ApiKey::Torn.create!(faction: @faction, key: "key")
    @faction.reload.api_keys.destroy_all
    assert_not ApiKey.exists?(api_key.id)
  end
end
