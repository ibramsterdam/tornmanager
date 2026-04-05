require "test_helper"

class FetchMemberActivityJobTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")
  end

  test "creates snapshots for all members" do
    members = [
      TornApi::Faction::Members::Member.new(111, "Alice", 50, 30, "Online", Time.current.to_i, "1 minute ago", nil, nil, nil, nil, nil, nil, nil, "Member", false, false, false, false),
      TornApi::Faction::Members::Member.new(222, "Bob", 40, 20, "Idle", Time.current.to_i, "5 minutes ago", nil, nil, nil, nil, nil, nil, nil, "Member", false, false, false, false)
    ]

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns(members)

    assert_difference "MemberActivitySnapshot.count", 2 do
      FetchMemberActivityJob.perform_now(@faction.id)
    end

    snapshot = MemberActivitySnapshot.find_by(torn_member_id: 111)
    assert_equal "Online", snapshot.status
    assert_equal "Alice", snapshot.member_name
    assert_equal @faction.id, snapshot.faction_id
  end

  test "skips faction without api key" do
    @faction.torn_api_key.destroy!
    @faction.reload

    assert_no_difference "MemberActivitySnapshot.count" do
      FetchMemberActivityJob.perform_now(@faction.id)
    end
  end

  test "skips non-existent faction" do
    assert_no_difference "MemberActivitySnapshot.count" do
      FetchMemberActivityJob.perform_now(0)
    end
  end

  test "inherits from FactionApiJob for rate limiting" do
    assert FetchMemberActivityJob < FactionApiJob
  end

  test "limits concurrency per faction in FactionApiCalls group" do
    assert_equal 1, FetchMemberActivityJob.concurrency_limit
    assert_equal "FactionApiCalls", FetchMemberActivityJob.concurrency_group

    job = FetchMemberActivityJob.new(@faction.id)
    assert_equal "FactionApiCalls/#{@faction.id}", job.concurrency_key
  end

  test "handles api errors gracefully" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).raises(TornApi::ApiError.new("Rate limited"))

    assert_nothing_raised do
      FetchMemberActivityJob.perform_now(@faction.id)
    end
  end
end
