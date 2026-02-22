require "test_helper"

class SyncFactionMembersJobTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(torn_id: 99999, name: "Test Faction", track_stats: true, xanax_target: 2.5)
    @bram = users(:bram)
    @bram.update!(faction: @faction)

    @member_data = TornApi::Faction::Members::Member.new(
      @bram.torn_id, "Bram", 69, 100,
      "Online", 1708000000, "5 minutes ago",
      "Okay", "", "Okay", "green", 0,
      "Everyone", "Leader", true, false, false, false
    )
  end

  test "syncs existing members from API response" do
    OwnerCredentials.stubs(:api_key).returns("test_key")
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @member_data ])

    SyncFactionMembersJob.perform_now(@faction.id)

    @bram.reload
    assert_equal @faction.id, @bram.faction_id
    assert_equal 69, @bram.level
  end

  test "creates new users for unknown members" do
    new_member = TornApi::Faction::Members::Member.new(
      9999999, "NewPlayer", 15, 5,
      "Online", 1708000000, "1 minute ago",
      "Okay", "", "Okay", "green", 0,
      "Everyone", "Member", true, false, false, false
    )
    OwnerCredentials.stubs(:api_key).returns("test_key")
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @member_data, new_member ])

    assert_difference "User.count", 1 do
      SyncFactionMembersJob.perform_now(@faction.id)
    end

    new_user = User.find_by(torn_id: 9999999)
    assert_equal "NewPlayer", new_user.name
    assert_equal @faction.id, new_user.faction_id
  end

  test "clears faction_id for departed members" do
    bert = users(:bert)
    bert.update!(faction: @faction)

    # API only returns bram, not bert — bert has departed
    OwnerCredentials.stubs(:api_key).returns("test_key")
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @member_data ])

    SyncFactionMembersJob.perform_now(@faction.id)

    assert_nil bert.reload.faction_id, "Departed member should have faction_id cleared"
    assert_equal @faction.id, @bram.reload.faction_id
  end

  test "marks fallen members" do
    fallen_member = TornApi::Faction::Members::Member.new(
      @bram.torn_id, "Bram", 69, 100,
      "Offline", 1708000000, "2 days ago",
      "Fallen", "", "Fallen", "red", 0,
      "Everyone", "Leader", false, false, false, false
    )
    OwnerCredentials.stubs(:api_key).returns("test_key")
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ fallen_member ])

    SyncFactionMembersJob.perform_now(@faction.id)

    assert @bram.reload.fallen
  end

  test "handles API error gracefully" do
    OwnerCredentials.stubs(:api_key).returns("test_key")
    TornApi::Faction::Members.any_instance.stubs(:fetch).raises(TornApi::ApiError, "Rate limited")

    assert_nothing_raised do
      SyncFactionMembersJob.perform_now(@faction.id)
    end
  end
end
