require "test_helper"

class Recon::TrainingSampleTest < ActiveSupport::TestCase
  def valid_attributes
    {
      player_id: 123456,
      strength: 1_000_000,
      defense: 2_000_000,
      speed: 500_000,
      dexterity: 750_000,
      spied_at: 1.day.ago
    }
  end

  test "valid with all required attributes" do
    sample = Recon::TrainingSample.new(valid_attributes)
    assert sample.valid?
  end

  test "requires player_id" do
    sample = Recon::TrainingSample.new(valid_attributes.except(:player_id))
    assert_not sample.valid?
  end

  test "requires strength" do
    sample = Recon::TrainingSample.new(valid_attributes.except(:strength))
    assert_not sample.valid?
  end

  test "requires defense" do
    sample = Recon::TrainingSample.new(valid_attributes.except(:defense))
    assert_not sample.valid?
  end

  test "requires speed" do
    sample = Recon::TrainingSample.new(valid_attributes.except(:speed))
    assert_not sample.valid?
  end

  test "requires dexterity" do
    sample = Recon::TrainingSample.new(valid_attributes.except(:dexterity))
    assert_not sample.valid?
  end

  test "requires spied_at" do
    sample = Recon::TrainingSample.new(valid_attributes.except(:spied_at))
    assert_not sample.valid?
  end

  test "total_stats sums all four battle stats" do
    sample = Recon::TrainingSample.new(valid_attributes)
    assert_equal 4_250_000, sample.total_stats
  end

  test "total_stats is zero when stats are zero" do
    sample = Recon::TrainingSample.new(strength: 0, defense: 0, speed: 0, dexterity: 0)
    assert_equal 0, sample.total_stats
  end

  test "features returns hash of all feature columns" do
    sample = Recon::TrainingSample.new(valid_attributes.merge(
      xantaken: 500, energydrinkused: 100, refills: 200, level: 80, real_age: 1000
    ))

    features = sample.features
    assert_equal 500, features["xantaken"]
    assert_equal 100, features["energydrinkused"]
    assert_equal 80, features["level"]
    assert_equal 1000, features["real_age"]
    assert_nil features["strength"], "Labels should not be in features"
    assert_nil features["player_id"], "Metadata should not be in features"
  end

  test "feature columns match the documented feature list" do
    expected = %w[
      xantaken energydrinkused refills daysbeendonator
      statenhancersused boostersused lsdtaken revives exttaken victaken
      rehabs highestbeaten hospital jobpointsused trainsreceived
      attackswon awards useractivity networth level property_happy real_age
    ]
    assert_equal expected.sort, Recon::TrainingSample::FEATURE_COLUMNS.sort
  end

  test "allows nil feature columns" do
    sample = Recon::TrainingSample.new(valid_attributes)
    assert sample.valid?
    assert_nil sample.xantaken
  end
end
