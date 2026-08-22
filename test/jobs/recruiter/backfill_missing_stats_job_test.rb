require "test_helper"

class Recruiter::BackfillMissingStatsJobTest < ActiveJob::TestCase
  test "schedules fetches for employed players with missing or stale stats" do
    never_fetched = users(:bert)
    never_fetched.update!(company_id: 91001, working_stats: nil, working_stats_at: nil)
    stale = users(:kaneki)
    stale.update!(company_id: 91001, working_stats: 5000, working_stats_at: 11.days.ago)
    fresh = users(:user_no_faction)
    fresh.update!(company_id: 91001, working_stats: 9000, working_stats_at: 1.day.ago)
    director = users(:user_hof_no_faction)
    director.update!(company_id: 91001, company_director: true, working_stats: nil)
    low_rated = users(:user_with_keyed_faction)
    low_rated.update!(company_id: 91003, working_stats: nil)

    Recruiter::BackfillMissingStatsJob.perform_now

    scheduled = enqueued_jobs
      .select { |job| job["job_class"] == "Recruiter::FetchPlayerHofJob" }
      .map { |job| job["arguments"].first }
    assert_equal [ never_fetched.id, stale.id ], scheduled
  end
end
