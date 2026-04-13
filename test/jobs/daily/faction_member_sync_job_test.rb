require "test_helper"

class Daily::FactionMemberSyncJobTest < ActiveJob::TestCase
  setup do
    Faction.update_all(setup_completed: false)

    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    ApiKey::Torn.create!(faction: @faction, key: "FACTION_KEY_123", access_type: "Limited Access")

    @bram = users(:bram)
    @bram.update!(faction: @faction)

    @member_data = TornApi::Faction::Members::Member.new(
      @bram.torn_id, "Bram", 69, 100,
      "Online", 1708000000, "5 minutes ago",
      "Okay", "", "Okay", "green", 0, nil,
      "Everyone", "Leader", true, false, false, false
    )
  end

  test "runs for each faction with setup completed and api key" do
    faction2 = Faction.create!(
      torn_id: 88888, name: "Other Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    ApiKey::Torn.create!(faction: faction2, key: "OTHER_KEY", access_type: "Limited Access")

    bert = users(:bert)
    bert.update!(faction: faction2)

    bert_member = TornApi::Faction::Members::Member.new(
      bert.torn_id, "Bert", 50, 30,
      "Online", 1708000000, "1 minute ago",
      "Okay", "", "Okay", "green", 0, nil,
      "Everyone", "Member", true, false, false, false
    )

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @member_data ]).then.returns([ bert_member ])

    Daily::FactionMemberSyncJob.perform_now

    assert_equal 2, enqueued_jobs.count { |j| j["job_class"] == "FetchPersonalStatsJob" }
  end

  test "skips factions without api key" do
    @faction.torn_api_key.destroy!

    Daily::FactionMemberSyncJob.perform_now

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob)
  end

  test "skips factions without setup completed" do
    @faction.update!(setup_completed: false)

    Daily::FactionMemberSyncJob.perform_now

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob)
  end

  test "syncs members then enqueues personal stats for each" do
    new_member = TornApi::Faction::Members::Member.new(
      9999999, "NewPlayer", 15, 5,
      "Online", 1708000000, "1 minute ago",
      "Okay", "", "Okay", "green", 0, nil,
      "Everyone", "Member", true, false, false, false
    )
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @member_data, new_member ])

    Daily::FactionMemberSyncJob.perform_now

    assert_equal 2, enqueued_jobs.count { |j| j["job_class"] == "FetchPersonalStatsJob" }
    assert User.exists?(torn_id: 9999999)
  end

  test "clears faction_id for departed members" do
    bert = users(:bert)
    bert.update!(faction: @faction)

    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @member_data ])

    Daily::FactionMemberSyncJob.perform_now

    assert_nil bert.reload.faction_id
  end

  test "skips fallen members for personal stats" do
    fallen_member = TornApi::Faction::Members::Member.new(
      @bram.torn_id, "Bram", 69, 100,
      "Offline", 1708000000, "2 days ago",
      "Fallen", "", "Fallen", "red", 0, nil,
      "Everyone", "Leader", false, false, false, false
    )
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ fallen_member ])

    Daily::FactionMemberSyncJob.perform_now

    assert_no_enqueued_jobs(only: FetchPersonalStatsJob)
  end

  test "handles API error gracefully" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).raises(TornApi::ApiError, "Rate limited")

    assert_nothing_raised do
      Daily::FactionMemberSyncJob.perform_now
    end
  end

  test "backfills missing days for existing members" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @member_data ])

    existing_dates = PersonalStatSnapshot.tracking_start_date..3.days.ago.to_date
    existing_dates.each do |date|
      @bram.personal_stat_snapshots.find_or_create_by!(date: date) do |s|
        s.drugs_xanax = 100
      end
    end

    Daily::FactionMemberSyncJob.perform_now

    backfill_jobs = enqueued_jobs.select { |j| j["job_class"] == "BackfillSingleStatJob" }
    assert backfill_jobs.size > 0, "Expected backfill jobs for missing days"
    assert backfill_jobs.size <= 2, "Expected at most 2 missing days (yesterday handled by FetchPersonalStatsJob)"
  end

  test "does not backfill when no gaps exist" do
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @member_data ])

    (PersonalStatSnapshot.tracking_start_date..PersonalStatSnapshot.tracking_end_date).each do |date|
      @bram.personal_stat_snapshots.find_or_create_by!(date: date) do |s|
        s.drugs_xanax = 100
      end
    end

    Daily::FactionMemberSyncJob.perform_now

    backfill_jobs = enqueued_jobs.select { |j| j["job_class"] == "BackfillSingleStatJob" }
    assert_equal 0, backfill_jobs.size
  end

  test "schedules backfill for new members" do
    new_member = TornApi::Faction::Members::Member.new(
      9999999, "NewPlayer", 15, 5,
      "Online", 1708000000, "1 minute ago",
      "Okay", "", "Okay", "green", 0, nil,
      "Everyone", "Member", true, false, false, false
    )
    TornApi::Faction::Members.any_instance.stubs(:fetch).returns([ @member_data, new_member ])

    assert_enqueued_with(job: BackfillUserStatsJob) do
      Daily::FactionMemberSyncJob.perform_now
    end
  end
end
