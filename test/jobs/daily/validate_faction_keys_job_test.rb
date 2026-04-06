require "test_helper"

class Daily::ValidateFactionKeysJobTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @api_key = ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")

    # Clear fixture user keys and other faction keys to isolate tests
    User.update_all(api_key: nil, api_access_type: nil)
    ApiKey::Torn.where.not(id: @api_key.id).destroy_all
  end

  test "keeps valid faction key with faction access" do
    stub_key_valid(faction: true)

    assert_no_difference "ApiKey::Torn.count" do
      Daily::ValidateFactionKeysJob.perform_now
    end

    assert @faction.reload.setup_completed?
    assert @api_key.reload.faction_access?
  end

  test "destroys faction key without faction access and resets setup" do
    stub_key_valid(faction: false)

    assert_difference "ApiKey::Torn.count", -1 do
      Daily::ValidateFactionKeysJob.perform_now
    end

    assert_not @faction.reload.setup_completed?
  end

  test "destroys invalid faction key and resets setup" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError)

    assert_difference "ApiKey::Torn.count", -1 do
      Daily::ValidateFactionKeysJob.perform_now
    end

    assert_not @faction.reload.setup_completed?
  end

  test "clears invalid user api key" do
    stub_key_valid(faction: true)

    user = users(:bram)
    user.update!(api_key: "USER_KEY_ABC", api_access_type: "Limited Access")

    invalid_info = stub
    invalid_info.stubs(:fetch).raises(TornApi::InvalidKeyError)

    valid_info = stub
    valid_info.stubs(:fetch).returns(TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: true, company: false),
      user: TornApi::Key::Info::UserData.new(id: 12345, faction_id: 99999, company_id: 0)
    ))

    TornApi::Key::Info.stubs(:new).with("FACTION_KEY_123").returns(valid_info)
    TornApi::Key::Info.stubs(:new).with("USER_KEY_ABC").returns(invalid_info)

    Daily::ValidateFactionKeysJob.perform_now

    user.reload
    assert_nil user.api_key
    assert_nil user.api_access_type
  end

  test "handles API errors gracefully" do
    TornApi::Key::Info.any_instance.stubs(:fetch).raises(TornApi::ApiError.new("Timeout"))

    assert_no_difference "ApiKey::Torn.count" do
      Daily::ValidateFactionKeysJob.perform_now
    end

    assert @faction.reload.setup_completed?
  end

  private

  def stub_key_valid(faction:)
    info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: 3, type: "Limited Access", faction: faction, company: false),
      user: TornApi::Key::Info::UserData.new(id: 12345, faction_id: 99999, company_id: 0)
    )
    TornApi::Key::Info.any_instance.stubs(:fetch).returns(info)
  end
end
