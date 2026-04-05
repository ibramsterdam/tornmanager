require "test_helper"

class MemberActivitySnapshotTest < ActiveSupport::TestCase
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
  end

  test "calendar_heatmap returns date/hour counts for active members" do
    now = Time.current
    create_snapshot(status: "Online", recorded_at: now)
    create_snapshot(status: "Idle", recorded_at: now)
    create_snapshot(status: "Offline", recorded_at: now)

    data = MemberActivitySnapshot.calendar_heatmap(@faction.id, Date.current, Date.current)
    assert_equal 2, data[[ Date.current.to_s, now.hour ]]
  end

  test "member_summary returns per-member counts" do
    now = Time.current
    3.times { create_snapshot(status: "Online", recorded_at: now, torn_member_id: 111, member_name: "Alice") }
    2.times { create_snapshot(status: "Idle", recorded_at: now, torn_member_id: 111, member_name: "Alice") }
    1.times { create_snapshot(status: "Offline", recorded_at: now, torn_member_id: 111, member_name: "Alice") }

    members = MemberActivitySnapshot.member_summary(@faction.id)
    alice = members.first
    assert_equal 6, alice.total_snapshots.to_i
    assert_equal 3, alice.online_count.to_i
    assert_equal 5, alice.active_count.to_i
  end

  test "peak_hour returns the most active hour" do
    now = Time.current.change(hour: 14)
    5.times { create_snapshot(status: "Online", recorded_at: now) }
    2.times { create_snapshot(status: "Online", recorded_at: now.change(hour: 8)) }

    assert_equal 14, MemberActivitySnapshot.peak_hour(@faction.id)
  end

  test "recent scope filters by days" do
    create_snapshot(recorded_at: 3.days.ago)
    create_snapshot(recorded_at: 10.days.ago)

    assert_equal 2, MemberActivitySnapshot.recent(30).count
    assert_equal 1, MemberActivitySnapshot.recent(7).count
  end

  test "belongs to faction" do
    snapshot = create_snapshot
    assert_equal @faction, snapshot.faction
  end

  private

  def create_snapshot(status: "Online", recorded_at: Time.current, torn_member_id: 12345, member_name: "Test")
    MemberActivitySnapshot.create!(
      faction: @faction,
      torn_member_id: torn_member_id,
      member_name: member_name,
      recorded_at: recorded_at,
      hour_utc: recorded_at.hour,
      day_of_week: recorded_at.wday,
      status: status
    )
  end
end
