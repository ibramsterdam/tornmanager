require "test_helper"

class DailyRankedWarRefreshJobTest < ActiveJob::TestCase
  setup do
    Faction.destroy_all
  end

  test "enqueues to the default queue" do
    assert_equal "default", Daily::RankedWarRefreshJob.new.queue_name
  end

  test "enqueues BackfillRankedWarsJob for factions with setup completed and API key configured" do
    faction = Faction.create!(torn_id: 99901, name: "War Ready", xanax_target: 2.5, setup_completed: true)
    FactionSetting.create!(faction: faction, torn_api_key: "abc123")

    assert_enqueued_jobs 1, only: BackfillRankedWarsJob do
      Daily::RankedWarRefreshJob.perform_now
    end

    enqueued = queue_adapter.enqueued_jobs.select { |j| j["job_class"] == "BackfillRankedWarsJob" }
    assert_equal [ faction.id ], enqueued.map { |j| j["arguments"].first }
  end

  test "skips factions without setup completed" do
    faction = Faction.create!(torn_id: 99902, name: "Not Setup", xanax_target: 2.5, setup_completed: false)
    FactionSetting.create!(faction: faction, torn_api_key: "abc123")

    assert_no_enqueued_jobs(only: BackfillRankedWarsJob) do
      Daily::RankedWarRefreshJob.perform_now
    end
  end

  test "skips factions without API key configured" do
    faction = Faction.create!(torn_id: 99903, name: "No Key", xanax_target: 2.5, setup_completed: true)
    FactionSetting.create!(faction: faction, torn_api_key: nil)

    assert_no_enqueued_jobs(only: BackfillRankedWarsJob) do
      Daily::RankedWarRefreshJob.perform_now
    end
  end

  test "skips factions with empty API key" do
    faction = Faction.create!(torn_id: 99904, name: "Empty Key", xanax_target: 2.5, setup_completed: true)
    FactionSetting.create!(faction: faction, torn_api_key: "")

    assert_no_enqueued_jobs(only: BackfillRankedWarsJob) do
      Daily::RankedWarRefreshJob.perform_now
    end
  end

  test "skips factions without faction setting" do
    Faction.create!(torn_id: 99905, name: "No Setting", xanax_target: 2.5, setup_completed: true)

    assert_no_enqueued_jobs(only: BackfillRankedWarsJob) do
      Daily::RankedWarRefreshJob.perform_now
    end
  end

  test "does nothing when no factions exist" do
    assert_no_enqueued_jobs(only: BackfillRankedWarsJob) do
      Daily::RankedWarRefreshJob.perform_now
    end
  end
end
