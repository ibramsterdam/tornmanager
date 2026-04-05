require "test_helper"

class MemberActivityPollJobTest < ActiveJob::TestCase
  test "enqueues fetch jobs for factions with setup completed and api key" do
    faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    ApiKey::Torn.create!(faction: faction, key: "FACTION_KEY_123", access_type: "Limited Access")

    assert_enqueued_with(job: FetchMemberActivityJob, args: [ faction.id ]) do
      MemberActivityPollJob.perform_now
    end
  end

  test "skips factions without setup completed" do
    Faction.where(setup_completed: true).update_all(setup_completed: false)

    Faction.create!(
      torn_id: 99998, name: "Incomplete Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: false
    )

    assert_no_enqueued_jobs(only: FetchMemberActivityJob) do
      MemberActivityPollJob.perform_now
    end
  end

  test "skips factions without api key" do
    Faction.where(setup_completed: true).update_all(setup_completed: false)

    Faction.create!(
      torn_id: 99997, name: "No Key Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )

    assert_no_enqueued_jobs(only: FetchMemberActivityJob) do
      MemberActivityPollJob.perform_now
    end
  end
end
