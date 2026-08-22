require "test_helper"

class Recruiter::FetchPlayerHofJobTest < ActiveJob::TestCase
  setup do
    Recruiter::KeyPool.stubs(:next_key).returns("pool_key")
    Recruiter::FetchPlayerHofJob.any_instance.stubs(:sleep)
    @bert = users(:bert)
  end

  test "stores the fetched working stats" do
    TornApi::User::Hof.any_instance.expects(:fetch).returns(321_000)

    Recruiter::FetchPlayerHofJob.perform_now(@bert.id)

    @bert.reload
    assert_equal 321_000, @bert.working_stats
    assert_not_nil @bert.working_stats_at
  end

  test "stores zero when working stats are hidden" do
    TornApi::User::Hof.any_instance.expects(:fetch).returns(nil)

    Recruiter::FetchPlayerHofJob.perform_now(@bert.id)

    assert_equal 0, @bert.reload.working_stats
  end

  test "stores zero when the player is not found" do
    TornApi::User::Hof.any_instance.expects(:fetch).raises(TornApi::NotFoundError, "Incorrect ID")

    Recruiter::FetchPlayerHofJob.perform_now(@bert.id)

    assert_equal 0, @bert.reload.working_stats
  end

  test "does nothing for a deleted user" do
    TornApi::User::Hof.any_instance.expects(:fetch).never

    Recruiter::FetchPlayerHofJob.perform_now(-1)
  end
end
