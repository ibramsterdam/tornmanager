require "test_helper"

class Daily::HofMemberSyncJobTest < ActiveJob::TestCase
  setup do
    User.update_all(hof_stats_user: false, faction_id: nil)
    @kaneki = users(:kaneki)
    @kaneki.update!(hof_stats_user: true, fallen: false)
    Rails.application.credentials.stubs(:dig).with(:kaneki, :api_key).returns("KANEKI_KEY")
  end

  test "enqueues FetchPersonalStatsJob with kaneki key for each hof user" do
    assert_enqueued_with(job: FetchPersonalStatsJob, args: [ @kaneki, { api_key: "KANEKI_KEY" } ]) do
      Daily::HofMemberSyncJob.perform_now
    end
  end

  test "skips when no kaneki key configured" do
    Rails.application.credentials.stubs(:dig).with(:kaneki, :api_key).returns(nil)

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob) do
      Daily::HofMemberSyncJob.perform_now
    end
  end

  test "skips fallen hof users" do
    @kaneki.update!(fallen: true)

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob) do
      Daily::HofMemberSyncJob.perform_now
    end
  end

  test "skips hof users who belong to a setup faction with api key" do
    faction = Faction.create!(
      torn_id: 99999, name: "Test", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    ApiKey::Torn.create!(faction: faction, key: "FK", access_type: "Limited Access")
    @kaneki.update!(faction: faction)

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob) do
      Daily::HofMemberSyncJob.perform_now
    end
  end

  test "includes hof users with no faction" do
    assert_enqueued_jobs 1, only: FetchPersonalStatsJob do
      Daily::HofMemberSyncJob.perform_now
    end
  end

  test "backfills missing days for hof users" do
    existing_dates = PersonalStatSnapshot.tracking_start_date..3.days.ago.to_date
    existing_dates.each do |date|
      @kaneki.personal_stat_snapshots.find_or_create_by!(date: date) do |s|
        s.drugs_xanax = 100
      end
    end

    Daily::HofMemberSyncJob.perform_now

    backfill_jobs = enqueued_jobs.select { |j| j["job_class"] == "BackfillSingleStatJob" }
    assert backfill_jobs.size > 0, "Expected backfill jobs for missing days"
  end

  test "does not backfill when hof user has no gaps" do
    (PersonalStatSnapshot.tracking_start_date..PersonalStatSnapshot.tracking_end_date).each do |date|
      create_complete_snapshot(@kaneki, date)
    end

    Daily::HofMemberSyncJob.perform_now

    backfill_jobs = enqueued_jobs.select { |j| j["job_class"] == "BackfillSingleStatJob" }
    assert_equal 0, backfill_jobs.size
  end

  test "includes hof users whose faction has no api key" do
    faction = Faction.create!(
      torn_id: 99999, name: "No Key Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @kaneki.update!(faction: faction)

    assert_enqueued_jobs 1, only: FetchPersonalStatsJob do
      Daily::HofMemberSyncJob.perform_now
    end
  end
end
