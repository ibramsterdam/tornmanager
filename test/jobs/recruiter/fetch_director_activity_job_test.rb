require "test_helper"

class Recruiter::FetchDirectorActivityJobTest < ActiveJob::TestCase
  setup do
    Recruiter::KeyPool.stubs(:next_key).returns("pool_key")
  end

  test "creates an unknown director with their last action" do
    stub_result(torn_id: 8888888, name: "Ghost", level: 40, last_action_at: Time.zone.at(1_790_000_000))

    assert_difference "User.count", 1 do
      Recruiter::FetchDirectorActivityJob.perform_now(8888888)
    end

    ghost = User.find_by!(torn_id: 8888888)
    assert_equal "Ghost", ghost.name
    assert_equal Time.zone.at(1_790_000_000), ghost.last_action_at
  end

  test "updates a known director without touching their account" do
    bert = users(:bert)
    stub_result(torn_id: bert.torn_id, name: "Bert", level: 52, last_action_at: Time.zone.at(1_790_000_000))

    Recruiter::FetchDirectorActivityJob.perform_now(bert.torn_id)

    bert.reload
    assert_equal Time.zone.at(1_790_000_000), bert.last_action_at
    assert_equal "1234567_api_token_fixture", bert.api_token
  end

  test "skips a director that does not exist" do
    TornApi::User::LastAction.any_instance.stubs(:fetch).raises(TornApi::NotFoundError, "Incorrect ID")

    assert_no_difference "User.count" do
      Recruiter::FetchDirectorActivityJob.perform_now(8888888)
    end
  end

  private

  def stub_result(**attributes)
    TornApi::User::LastAction.any_instance.stubs(:fetch).returns(TornApi::User::LastAction::Result.new(**attributes))
  end
end
