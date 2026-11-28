require "test_helper"

class Recruiter::RefreshDirectorActivityJobTest < ActiveJob::TestCase
  test "schedules directors missing from the roster whose activity is unknown or stale" do
    synced_at = 1.hour.ago
    companies(:adult_novelties).update!(synced_at: synced_at, director_torn_id: 8888888)

    users(:bert).update!(company_synced_at: 10.days.ago, last_action_at: 20.days.ago)
    companies(:television_network).update!(synced_at: synced_at, director_torn_id: users(:bert).torn_id)

    users(:kaneki).update!(company_synced_at: 10.days.ago, last_action_at: 11.days.ago)
    companies(:budget_shop).update!(synced_at: synced_at, director_torn_id: users(:kaneki).torn_id)

    Recruiter::RefreshDirectorActivityJob.perform_now

    scheduled = enqueued_jobs
      .select { |job| job["job_class"] == "Recruiter::FetchDirectorActivityJob" }
      .map { |job| job["arguments"].first }
    assert_equal [ 8888888, users(:bert).torn_id ], scheduled
  end

  test "skips directors in the latest roster" do
    synced_at = 1.hour.ago
    users(:bert).update!(company_synced_at: synced_at, last_action_at: nil)
    companies(:adult_novelties).update!(synced_at: synced_at, director_torn_id: users(:bert).torn_id)

    Recruiter::RefreshDirectorActivityJob.perform_now

    assert_empty enqueued_jobs.select { |job| job["job_class"] == "Recruiter::FetchDirectorActivityJob" }
  end
end
