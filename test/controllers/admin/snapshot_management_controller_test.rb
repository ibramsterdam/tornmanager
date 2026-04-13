require "test_helper"

class Admin::SnapshotManagementControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bram = users(:bram)
    @bert = users(:bert)
    @faction = factions(:with_api_key)
    @bram.update!(faction: @faction)
    @bert.update!(faction: @faction)
  end

  test "backfill_user passes the faction api key to the job" do
    sign_in_as(@bram)
    stub_solid_queue_count

    assert_enqueued_with(
      job: BackfillSingleStatJob,
      args: ->(args) { args.last[:api_key] == api_keys(:faction_with_key_torn).key }
    ) do
      post backfill_user_admin_snapshot_management_path(@bert)
    end
  end

  test "backfill_user falls back to kaneki key for hof user without faction" do
    sign_in_as(@bram)
    stub_solid_queue_count
    Rails.application.credentials.stubs(:dig).with(:kaneki, :api_key).returns("kaneki_key")

    hof_user = users(:user_hof_no_faction)

    assert_enqueued_with(
      job: BackfillSingleStatJob,
      args: ->(args) { args.last[:api_key] == "kaneki_key" }
    ) do
      post backfill_user_admin_snapshot_management_path(hof_user)
    end
  end

  test "backfill_user returns error when no api key available" do
    sign_in_as(@bram)
    stub_solid_queue_count
    Rails.application.credentials.stubs(:dig).with(:kaneki, :api_key).returns(nil)

    hof_user = users(:user_hof_no_faction)
    post backfill_user_admin_snapshot_management_path(hof_user)

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "non-admin cannot access backfill_user" do
    sign_in_as(@bert)
    post backfill_user_admin_snapshot_management_path(@bert)
    assert_redirected_to root_path
  end

  test "backfill_user sets backfill_ends_at" do
    sign_in_as(@bram)
    stub_solid_queue_count

    post backfill_user_admin_snapshot_management_path(@bert)

    @bert.reload
    assert @bert.backfill_ends_at.present?
    assert @bert.backfill_ends_at > Time.current
  end

  private

  def stub_solid_queue_count
    relation = mock
    relation.stubs(:count).returns(0)
    SolidQueue::Job.stubs(:where).returns(relation)
  end
end
