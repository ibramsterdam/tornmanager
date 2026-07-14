require "test_helper"

# End-to-end composition of the three layers: a job whose key is out of budget
# is rejected before any HTTP happens and re-scheduled, while a job on a
# different key sails through the whole real pipeline (budget gate -> HTTP ->
# parse -> snapshot) at the same moment.
class TornApiBudgetFlowTest < ActiveJob::TestCase
  setup do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)

    @faction = Faction.create!(
      torn_id: 99999, name: "Test Faction", xanax_target: 2.5,
      energy_refill_target: 1.0, nerve_refill_target: 1.0, setup_completed: true
    )
    ApiKey::Torn.create!(faction: @faction, key: "KEY_A", access_type: "Limited Access")

    @user = users(:bram)
    @user.update!(faction: @faction)
    @stats_date = Date.new(2026, 2, 19)
  end

  test "a job on an exhausted key is rescheduled without touching the network" do
    50.times { TornApi::RateLimiter.acquire!("KEY_A") }
    TornApi::Base.any_instance.expects(:perform_request).never

    assert_enqueued_with(job: FetchPersonalStatsJob) do
      FetchPersonalStatsJob.perform_now(@user, api_key: "KEY_A", batch: 1, stats_date: @stats_date)
    end

    assert_not @user.personal_stat_snapshots.exists?(date: @stats_date)
  end

  test "a job on a fresh key completes the full pipeline while another key is exhausted" do
    50.times { TornApi::RateLimiter.acquire!("KEY_A") }

    payload = {
      "personalstats" => [
        { "name" => "xantaken", "value" => 42, "timestamp" => @stats_date.end_of_day.to_i }
      ]
    }
    TornApi::Base.any_instance.stubs(:perform_request)
      .returns(stub(code: "200", body: payload.to_json))

    FetchPersonalStatsJob.perform_now(@user, api_key: "KEY_B", batch: 1, stats_date: @stats_date)

    snapshot = @user.personal_stat_snapshots.find_by(date: @stats_date)
    assert snapshot, "fresh key must complete and persist the snapshot"
    assert_equal 42, snapshot.drugs_xanax
    assert_operator TornApi::RateLimiter.remaining("KEY_B"), :<, 50,
      "the successful call must have consumed KEY_B budget"
  end
end
