require "test_helper"

class TornApi::BaseInvalidateKeyTest < ActiveSupport::TestCase
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @api_key = ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")
  end

  test "invalidates faction api key and resets faction setup" do
    base = TornApi::Base.new("FACTION_KEY_123")
    base.send(:invalidate_api_key!)

    assert_not ApiKey.exists?(@api_key.id), "API key should be destroyed"
    assert_not @faction.reload.setup_completed?, "Faction setup should be reset"
  end

  test "does not invalidate admin api key" do
    admin_key = "ADMIN_KEY_SECRET"
    AdminCredentials.stubs(:api_key).returns(admin_key)

    base = TornApi::Base.new(admin_key)
    base.send(:invalidate_api_key!)

    assert ApiKey.exists?(@api_key.id), "Faction API key should not be touched"
  end

  test "handles missing api key record gracefully" do
    base = TornApi::Base.new("NONEXISTENT_KEY")
    assert_nothing_raised do
      base.send(:invalidate_api_key!)
    end
  end

  test "invalidates user api key" do
    user = users(:bram)
    user.set_api_key!("USER_KEY_ABC", "Limited Access")
    user_key = user.torn_api_key

    base = TornApi::Base.new("USER_KEY_ABC")
    base.send(:invalidate_api_key!)

    assert_not ApiKey.exists?(user_key.id), "User API key should be destroyed"
  end

  test "is idempotent when called multiple times" do
    base = TornApi::Base.new("FACTION_KEY_123")

    assert_nothing_raised do
      base.send(:invalidate_api_key!)
      base.send(:invalidate_api_key!)
    end

    assert_not ApiKey.exists?(@api_key.id)
  end
end
