require "test_helper"

class Recon::FeatureSetTest < ActiveSupport::TestCase
  test "returns a plain hash" do
    features = build_features
    assert_instance_of Hash, features
  end

  test "includes personalstat values" do
    features = build_features(personalstats: { "xantaken" => 500, "energydrinkused" => 100, "refills" => 200 })

    assert_equal 500, features["xantaken"]
    assert_equal 100, features["energydrinkused"]
    assert_equal 200, features["refills"]
  end

  test "defaults missing personalstats to zero" do
    features = build_features(personalstats: { "xantaken" => 500 })

    assert_equal 500, features["xantaken"]
    assert_equal 0, features["energydrinkused"]
    assert_equal 0, features["refills"]
  end

  test "includes level from profile" do
    features = build_features(level: 75)
    assert_equal 75, features["level"]
  end

  test "maps Private Island to 5025 happy" do
    features = build_features(property: "Private Island")
    assert_equal 5025, features["property_happy"]
  end

  test "maps Castle to 3475 happy" do
    features = build_features(property: "Castle")
    assert_equal 3475, features["property_happy"]
  end

  test "maps Shack to 100 happy" do
    features = build_features(property: "Shack")
    assert_equal 100, features["property_happy"]
  end

  test "defaults nil property to 100" do
    features = build_features(property: nil)
    assert_equal 100, features["property_happy"]
  end

  test "calculates real_age as age minus inactive days" do
    features = build_features(age: 1000, last_action_timestamp: Time.now.to_i - 86_400)
    assert_equal 999, features["real_age"]
  end

  test "real_age floors at zero" do
    features = build_features(age: 1000, last_action_timestamp: Time.now.to_i - (5000 * 86_400))
    assert_equal 0, features["real_age"]
  end

  test "uses full age when last_action_timestamp is nil" do
    features = build_features(age: 1000, last_action_timestamp: nil)
    assert_equal 1000, features["real_age"]
  end

  test "maps timeplayed API name to useractivity column" do
    features = build_features(personalstats: { "timeplayed" => 999_999 })
    assert_equal 999_999, features["useractivity"]
  end

  test "returns all expected feature keys" do
    features = build_features
    Recon::TrainingSample::FEATURE_COLUMNS.each do |col|
      assert features.key?(col), "Missing feature: #{col}"
    end
  end

  test "returns no extra keys beyond feature columns" do
    features = build_features
    extra = features.keys - Recon::TrainingSample::FEATURE_COLUMNS
    assert_empty extra, "Unexpected keys: #{extra}"
  end

  private

  def build_features(personalstats: {}, age: 1000, level: 50, property: nil, last_action_timestamp: Time.now.to_i)
    profile = Recon::TornApi::Profile::ProfileData.new(
      age: age, level: level, property: property, last_action_timestamp: last_action_timestamp
    )
    Recon::FeatureSet.build(personalstats: personalstats, profile: profile)
  end
end
