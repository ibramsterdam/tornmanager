require "test_helper"

class Recruiter::CompanyStatusJobTest < ActiveJob::TestCase
  setup do
    Recruiter::KeyPool.stubs(:next_key).returns("pool_key")
    Recruiter::CompanyStatusJob.any_instance.stubs(:sleep)
  end

  test "caches the employee statuses for a company" do
    employee = TornApi::Company::Employees::Employee.new(
      torn_id: 1234567,
      status: "Online",
      relative: "0 minutes ago",
      last_action_at: 1_755_800_000,
      position: "Employee",
      days_in_company: 45
    )
    TornApi::Company::Employees.any_instance.expects(:fetch).returns([ employee ])

    expected = [ {
      torn_id: 1234567,
      status: "Online",
      relative: "0 minutes ago",
      last_action_at: 1_755_800_000,
      position: "Employee",
      days_in_company: 45
    } ]
    Rails.cache.expects(:write).with("recruiter:status:91001", expected, expires_in: 5.minutes)

    Recruiter::CompanyStatusJob.perform_now(91001)
  end
end
