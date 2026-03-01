require "test_helper"

class Admin::SnapshotManagementControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bram = users(:bram)
    @bert = users(:bert)
    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction",
      xanax_target: 2.5, energy_refill_target: 1.0, nerve_refill_target: 1.0,
      setup_completed: true
    )
    @bram.update!(faction: @faction)
    @bert.update!(faction: @faction)
  end

  test "non-admin cannot access backfill_all" do
    sign_in_as(@bert)
    post backfill_all_admin_snapshot_management_index_path
    assert_redirected_to root_path
  end

  test "unauthenticated user cannot access backfill_all" do
    post backfill_all_admin_snapshot_management_index_path
    assert_redirected_to new_session_path
  end

  test "backfill_all queues jobs for all users with missing snapshots" do
    sign_in_as(@bram)
    stub_solid_queue_count

    assert_enqueued_with(job: BackfillSingleStatJob) do
      post backfill_all_admin_snapshot_management_index_path
    end

    assert_redirected_to admin_snapshot_management_index_path
    assert_match /Backfilling/, flash[:notice]
  end

  test "backfill_all sets backfill_ends_at on all users" do
    sign_in_as(@bram)
    stub_solid_queue_count

    post backfill_all_admin_snapshot_management_index_path

    [@bram, @bert].each do |user|
      user.reload
      assert user.backfill_ends_at.present?, "#{user.name} should have backfill_ends_at set"
      assert user.backfill_ends_at > Time.current, "#{user.name} backfill_ends_at should be in the future"
    end
  end

  test "backfill_all does nothing when no users have gaps" do
    sign_in_as(@bram)
    stub_solid_queue_count

    expected_dates = PersonalStatSnapshot.tracking_start_date..PersonalStatSnapshot.tracking_end_date
    [@bram, @bert].each do |user|
      expected_dates.each do |date|
        PersonalStatSnapshot.create!(user: user, date: date, drugs_xanax: 10)
      end
    end

    assert_no_enqueued_jobs(only: BackfillSingleStatJob) do
      post backfill_all_admin_snapshot_management_index_path
    end

    assert_redirected_to admin_snapshot_management_index_path
    assert_match /Backfilling 0 users/, flash[:notice]
  end

  test "backfill_all skips users already being backfilled" do
    original_backfill = 1.hour.from_now
    @bert.update!(backfill_ends_at: original_backfill)
    sign_in_as(@bram)
    stub_solid_queue_count

    post backfill_all_admin_snapshot_management_index_path

    @bert.reload
    assert_in_delta original_backfill.to_i, @bert.backfill_ends_at.to_i, 5,
      "Bert's backfill_ends_at should not be overwritten since he was already backfilling"
  end

  private

  def stub_solid_queue_count
    relation = mock
    relation.stubs(:count).returns(0)
    SolidQueue::Job.stubs(:where).returns(relation)
  end
end
