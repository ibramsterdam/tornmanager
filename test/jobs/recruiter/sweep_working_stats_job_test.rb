require "test_helper"

class Recruiter::SweepWorkingStatsJobTest < ActiveJob::TestCase
  setup do
    Recruiter::KeyPool.stubs(:next_key).returns("pool_key")
    Recruiter::SweepWorkingStatsJob.any_instance.stubs(:sleep)
    @bert = users(:bert)
  end

  test "updates known users and stops once the floor is reached" do
    full_page = Array.new(100) do |i|
      leaderboard_row(torn_id: 900000 + i, value: 600_000 - i)
    end
    full_page[10] = leaderboard_row(torn_id: @bert.torn_id, value: 480_000)
    below_floor_page = [ leaderboard_row(torn_id: 910000, value: 100) ]

    TornApi::Torn::HofLeaderboard.any_instance.expects(:fetch).twice
      .returns(full_page).then.returns(below_floor_page)

    assert_no_difference "User.count" do
      Recruiter::SweepWorkingStatsJob.perform_now
    end

    @bert.reload
    assert_equal 480_000, @bert.working_stats
    assert_not_nil @bert.working_stats_at
  end

  test "skips when no key is available" do
    Recruiter::KeyPool.stubs(:next_key).returns(nil)
    TornApi::Torn::HofLeaderboard.any_instance.expects(:fetch).never

    Recruiter::SweepWorkingStatsJob.perform_now
  end

  private

  def leaderboard_row(torn_id:, value:)
    TornApi::Torn::HofLeaderboard::Row.new(
      torn_id: torn_id, name: "Player#{torn_id}", level: 50, value: value, last_action: 1_755_800_000
    )
  end
end
