require "test_helper"

class Recon::CollectTrainingSampleJobTest < ActiveJob::TestCase
  setup do
    @sample = Recon::TrainingSample.create!(
      player_id: 1485341,
      strength: 5_751_694_281,
      defense: 7_905_360_376,
      speed: 4_692_172_959,
      dexterity: 297_478_845,
      spied_at: Date.new(2026, 3, 24)
    )

    @personalstats = {
      "xantaken" => 500,
      "energydrinkused" => 100,
      "refills" => 200,
      "statenhancersused" => 300,
      "attackswon" => 5000,
      "networth" => 10_000_000
    }

    @profile = Recon::TornApi::Profile::ProfileData.new(
      age: 4500, level: 78, property: "Private Island", last_action_timestamp: Time.now.to_i
    )
  end

  test "updates existing sample with features" do
    stub_api_calls

    Recon::CollectTrainingSampleJob.perform_now(player_id: 1485341, spied_at: "2026-03-24")

    @sample.reload
    assert_equal 500, @sample.xantaken
    assert_equal 78, @sample.level
    assert_equal 5025, @sample.property_happy
  end

  test "does not change spy labels" do
    stub_api_calls

    Recon::CollectTrainingSampleJob.perform_now(player_id: 1485341, spied_at: "2026-03-24")

    @sample.reload
    assert_equal 5_751_694_281, @sample.strength
    assert_equal 7_905_360_376, @sample.defense
  end

  test "skips if sample does not exist" do
    stub_api_calls

    # Should not raise
    Recon::CollectTrainingSampleJob.perform_now(player_id: 9999999, spied_at: "2026-03-24")
  end

  test "handles API errors gracefully" do
    AdminCredentials.stubs(:api_key).returns("test_admin_key")
    Recon::TornApi::PersonalStats.any_instance.stubs(:fetch).raises(TornApi::ApiError, "rate limited")

    Recon::CollectTrainingSampleJob.perform_now(player_id: 1485341, spied_at: "2026-03-24")

    @sample.reload
    assert_nil @sample.xantaken
  end

  test "skips if no admin api key" do
    AdminCredentials.stubs(:api_key).returns(nil)

    Recon::CollectTrainingSampleJob.perform_now(player_id: 1485341, spied_at: "2026-03-24")

    @sample.reload
    assert_nil @sample.xantaken
  end

  private

  def stub_api_calls
    AdminCredentials.stubs(:api_key).returns("test_admin_key")
    Recon::TornApi::PersonalStats.any_instance.stubs(:fetch).returns(@personalstats)
    Recon::TornApi::Profile.any_instance.stubs(:fetch).returns(@profile)
  end
end
