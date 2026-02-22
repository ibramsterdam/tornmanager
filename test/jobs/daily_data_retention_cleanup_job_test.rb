require "test_helper"

class DailyDataRetentionCleanupJobTest < ActiveJob::TestCase
  test "enqueues to the default queue" do
    assert_equal "default", Daily::DataRetentionCleanupJob.new.queue_name
  end

  test "deletes sessions older than 90 days" do
    bram = users(:bram)
    old_session = Session.create!(user: bram, created_at: 91.days.ago)
    recent_session = Session.create!(user: bram, created_at: 89.days.ago)

    Daily::DataRetentionCleanupJob.perform_now

    assert_not Session.exists?(old_session.id), "Old session should be deleted"
    assert Session.exists?(recent_session.id), "Recent session should be kept"
  end

  test "deletes api calls older than 30 days" do
    bram = users(:bram)

    # The fixtures create api_calls too, so we count from our new ones
    old_call = ApiCall.create!(
      user: bram, api_key: "test", endpoint: "/user",
      status: "success", created_at: 31.days.ago
    )
    recent_call = ApiCall.create!(
      user: bram, api_key: "test", endpoint: "/user",
      status: "success", created_at: 29.days.ago
    )

    Daily::DataRetentionCleanupJob.perform_now

    assert_not ApiCall.exists?(old_call.id), "Old API call should be deleted"
    assert ApiCall.exists?(recent_call.id), "Recent API call should be kept"
  end

  test "handles empty tables gracefully" do
    Session.delete_all
    ApiCall.delete_all

    assert_nothing_raised do
      Daily::DataRetentionCleanupJob.perform_now
    end
  end
end
