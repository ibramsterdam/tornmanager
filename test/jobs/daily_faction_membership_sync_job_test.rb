require "test_helper"

class DailyFactionMembershipSyncJobTest < ActiveJob::TestCase
  test "enqueues to the default queue" do
    assert_equal "default", Daily::FactionMembershipSyncJob.new.queue_name
  end

  test "enqueues SyncFactionMembersJob for each faction" do
    faction1 = Faction.create!(torn_id: 11111, name: "Faction One", xanax_target: 2.5)
    faction2 = Faction.create!(torn_id: 22222, name: "Faction Two", xanax_target: 2.5)

    perform_enqueued_jobs(only: Daily::FactionMembershipSyncJob) do
      Daily::FactionMembershipSyncJob.perform_now
    end

    enqueued = queue_adapter.enqueued_jobs.select { |j| j["job_class"] == "SyncFactionMembersJob" }
    faction_ids = enqueued.map { |j| j["arguments"].first }
    assert_includes faction_ids, faction1.id
    assert_includes faction_ids, faction2.id
  end

  test "does nothing when no factions exist" do
    Faction.destroy_all

    assert_no_enqueued_jobs(only: SyncFactionMembersJob) do
      Daily::FactionMembershipSyncJob.perform_now
    end
  end
end
