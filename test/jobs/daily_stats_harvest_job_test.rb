require "test_helper"

class DailyPersonalStatsJobTest < ActiveJob::TestCase
  test "enqueues to the default queue" do
    assert_equal "default", Daily::PersonalStatsJob.new.queue_name
  end

  test "enqueues a FetchPersonalStatsJob for each tracked user" do
    faction = Faction.create!(torn_id: 99999, name: "Test Faction", xanax_target: 2.5)
    bram = users(:bram)
    bert = users(:bert)
    bram.update!(faction: faction, fallen: false)
    bert.update!(faction: faction, fallen: false)

    # kaneki has no faction but is hof_stats_user
    kaneki = users(:kaneki)
    kaneki.update!(hof_stats_user: true, fallen: false)

    assert_enqueued_jobs 3, only: FetchPersonalStatsJob do
      Daily::PersonalStatsJob.perform_now
    end
  end

  test "skips fallen users" do
    faction = Faction.create!(torn_id: 99999, name: "Test Faction", xanax_target: 2.5)
    bram = users(:bram)
    bram.update!(faction: faction, fallen: true)

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob) do
      Daily::PersonalStatsJob.perform_now
    end
  end
end
