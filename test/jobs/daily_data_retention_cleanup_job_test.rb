require "test_helper"

class DailyDataRetentionCleanupJobTest < ActiveJob::TestCase
  test "enqueues to the default queue" do
    assert_equal "default", Daily::DataRetentionCleanupJob.new.queue_name
  end

  test "deletes sessions older than 90 days" do
    bram = users(:bram)
    old_session = Session.create!(user: bram, created_at: 91.days.ago)
    recent_session = Session.create!(user: bram, created_at: 89.days.ago)

    Daily::DataRetentionCleanupJob.perform_now

    assert_not Session.exists?(old_session.id), "Old session should be deleted"
    assert Session.exists?(recent_session.id), "Recent session should be kept"
  end

  test "deletes api calls older than 30 days" do
    bram = users(:bram)

    # The fixtures create api_calls too, so we count from our new ones
    old_call = ApiCall.create!(
      user: bram, api_key: "test", endpoint: "/user",
      status: "success", created_at: 31.days.ago
    )
    recent_call = ApiCall.create!(
      user: bram, api_key: "test", endpoint: "/user",
      status: "success", created_at: 29.days.ago
    )

    Daily::DataRetentionCleanupJob.perform_now

    assert_not ApiCall.exists?(old_call.id), "Old API call should be deleted"
    assert ApiCall.exists?(recent_call.id), "Recent API call should be kept"
  end

  test "deletes stale factions with their data but keeps their users" do
    faction = Faction.create!(torn_id: 77001, name: "Stale Crew", xanax_target: 2.5, setup_completed: false)
    member = User.create!(torn_id: 770_011, name: "StaleMember", level: 5, faction_id: faction.id)
    faction.armory_news_entries.create!(torn_news_id: "sn1", player_id: 1, player_name: "x", action: "used", occurred_at: 2.months.ago)
    faction.update_column(:updated_at, 31.days.ago)

    Daily::DataRetentionCleanupJob.perform_now

    assert_not Faction.exists?(faction.id), "stale faction should be removed"
    assert User.exists?(member.id), "members must never be deleted"
    assert_nil member.reload.faction_id, "members are detached, not destroyed"
    assert_equal 0, ArmoryNewsEntry.where(torn_news_id: "sn1").count
  end

  test "keeps stale factions that completed setup" do
    faction = Faction.create!(torn_id: 77002, name: "Old But Active", xanax_target: 2.5, setup_completed: true)
    faction.update_column(:updated_at, 100.days.ago)

    Daily::DataRetentionCleanupJob.perform_now

    assert Faction.exists?(faction.id)
  end

  test "keeps unconfigured factions that changed recently" do
    faction = Faction.create!(torn_id: 77003, name: "Fresh Signup", xanax_target: 2.5, setup_completed: false)
    faction.update_column(:updated_at, 29.days.ago)

    Daily::DataRetentionCleanupJob.perform_now

    assert Faction.exists?(faction.id)
  end

  test "keeps stale factions that still have a torn api key" do
    faction = Faction.create!(torn_id: 77004, name: "Keyed Crew", xanax_target: 2.5, setup_completed: false)
    ApiKey::Torn.create!(faction: faction, key: "STALE_BUT_KEYED", access_type: "Limited Access")
    faction.update_column(:updated_at, 60.days.ago)

    Daily::DataRetentionCleanupJob.perform_now

    assert Faction.exists?(faction.id)
  end

  test "keeps stale factions with an active subscription" do
    faction = Faction.create!(torn_id: 77005, name: "Paying Ghost", xanax_target: 2.5, setup_completed: false)
    grant_subscription(faction, expires_at: 1.month.from_now)
    faction.update_column(:updated_at, 60.days.ago)

    Daily::DataRetentionCleanupJob.perform_now

    assert Faction.exists?(faction.id)
  end

  test "handles empty tables gracefully" do
    Session.delete_all
    ApiCall.delete_all

    assert_nothing_raised do
      Daily::DataRetentionCleanupJob.perform_now
    end
  end
end
