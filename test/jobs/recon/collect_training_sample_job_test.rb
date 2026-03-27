require "test_helper"

class Recon::CollectTrainingSampleJobTest < ActiveJob::TestCase
  setup do
    @params = {
      player_id: 1485341,
      strength: 5_751_694_281,
      defense: 7_905_360_376,
      speed: 4_692_172_959,
      dexterity: 297_478_845,
      spied_at: "2026-03-24"
    }

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

  test "creates a training sample with features and labels" do
    stub_api_calls

    assert_difference "Recon::TrainingSample.count", 1 do
      Recon::CollectTrainingSampleJob.perform_now(**@params)
    end

    sample = Recon::TrainingSample.last
    assert_equal 1485341, sample.player_id
    assert_equal 5_751_694_281, sample.strength
    assert_equal 7_905_360_376, sample.defense
    assert_equal 4_692_172_959, sample.speed
    assert_equal 297_478_845, sample.dexterity
    assert_equal Date.new(2026, 3, 24), sample.spied_at.to_date
    assert_equal 500, sample.xantaken
    assert_equal 78, sample.level
  end

  test "fetches personalstats in batches and creates sample" do
    stub_api_calls

    Recon::CollectTrainingSampleJob.perform_now(**@params)

    sample = Recon::TrainingSample.last
    assert_equal 500, sample.xantaken
  end

  test "skips if training sample already exists for player and date" do
    Recon::TrainingSample.create!(
      player_id: 1485341,
      strength: 1, defense: 1, speed: 1, dexterity: 1,
      spied_at: Date.new(2026, 3, 24)
    )

    assert_no_difference "Recon::TrainingSample.count" do
      Recon::CollectTrainingSampleJob.perform_now(**@params)
    end
  end

  test "handles API errors gracefully" do
    Recon::TornApi::PersonalStats.any_instance.stubs(:fetch).raises(TornApi::ApiError, "rate limited")

    assert_no_difference "Recon::TrainingSample.count" do
      Recon::CollectTrainingSampleJob.perform_now(**@params)
    end
  end

  private

  def stub_api_calls
    Recon::TornApi::PersonalStats.any_instance.stubs(:fetch).returns(@personalstats)
    Recon::TornApi::Profile.any_instance.stubs(:fetch).returns(@profile)
  end
end
