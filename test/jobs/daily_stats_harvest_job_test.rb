require "test_helper"

class DailyPersonalStatsJobTest < ActiveJob::TestCase
  setup do
    # Clear fixture users from tracked scope so we control exactly who is tracked
    User.where.not(torn_id: [ 2728237, 1234567, 2685512 ]).update_all(faction_id: nil, hof_stats_user: false)
  end

  test "enqueues to the default queue" do
    assert_equal "default", Daily::PersonalStatsJob.new.queue_name
  end

  test "enqueues a FetchPersonalStatsJob for each tracked user" do
    faction = Faction.create!(torn_id: 99999, name: "Test Faction", xanax_target: 2.5)
    FactionSetting.create!(faction: faction)
    ApiKey::Torn.create!(faction: faction, key: "test_key")
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
    FactionSetting.create!(faction: faction)
    ApiKey::Torn.create!(faction: faction, key: "test_key")
    bram = users(:bram)
    bram.update!(faction: faction, fallen: true)

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob) do
      Daily::PersonalStatsJob.perform_now
    end
  end
end
