require "test_helper"

# The nightly gap scans enqueue one backfill per missing date per user with no
# upper bound — a user with 100 gaps adds ~200 API calls to a single key in
# one night. Cap the per-user enqueue and take the most recent dates first
# (recent snapshots are the valuable ones; older gaps fill on later nights).
class BackfillGapLimitTest < ActiveJob::TestCase
  setup do
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    @user = User.create!(torn_id: 424_242, name: "Gapster", level: 10, faction_id: @faction.id)

    # 100-day tracking window, user has no snapshots at all -> 100 missing dates
    @window_start = Date.new(2026, 3, 1)
    @window_end = Date.new(2026, 6, 8)
    PersonalStatSnapshot.stubs(:tracking_start_date).returns(@window_start)
    PersonalStatSnapshot.stubs(:tracking_end_date).returns(@window_end)
  end

  test "faction member sync caps backfills per user per night" do
    assert_enqueued_jobs Daily::FactionMemberSyncJob::BACKFILL_GAP_LIMIT, only: BackfillSingleStatJob do
      Daily::FactionMemberSyncJob.new.send(:backfill_gaps, @user, "FACTION_KEY_123")
    end
  end

  test "faction member sync backfills the most recent gaps first" do
    Daily::FactionMemberSyncJob.new.send(:backfill_gaps, @user, "FACTION_KEY_123")

    enqueued_dates = enqueued_jobs
      .select { |j| j[:job] == BackfillSingleStatJob }
      .map { |j| j[:args][1] }

    assert_includes enqueued_dates, @window_end.to_s, "newest gap must be scheduled"
    assert_not_includes enqueued_dates, @window_start.to_s, "oldest gap waits for a later night"
  end

  test "hof member sync caps backfills per user per night" do
    assert_enqueued_jobs Daily::HofMemberSyncJob::BACKFILL_GAP_LIMIT, only: BackfillSingleStatJob do
      Daily::HofMemberSyncJob.new.send(:backfill_gaps, @user, "KANEKI_KEY")
    end
  end

  test "no jobs are enqueued when there are no gaps" do
    (@window_start..@window_end).each do |date|
      @user.personal_stat_snapshots.create!(date: date)
    end

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      Daily::FactionMemberSyncJob.new.send(:backfill_gaps, @user, "FACTION_KEY_123")
    end
  end
end
