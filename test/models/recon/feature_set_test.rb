require "test_helper"

class Recon::FeatureSetTest < ActiveSupport::TestCase
  test "includes personalstat values" do
    features = build_feature_set(personalstats: { "xantaken" => 500, "energydrinkused" => 100, "refills" => 200 })

    assert_equal 500, features["xantaken"]
    assert_equal 100, features["energydrinkused"]
    assert_equal 200, features["refills"]
  end

  test "defaults missing personalstats to zero" do
    features = build_feature_set(personalstats: { "xantaken" => 500 })

    assert_equal 500, features["xantaken"]
    assert_equal 0, features["energydrinkused"]
    assert_equal 0, features["refills"]
  end

  test "includes level from profile" do
    features = build_feature_set(level: 75)
    assert_equal 75, features["level"]
  end

  test "maps Private Island to 4225 happy" do
    features = build_feature_set(property: "Private Island")
    assert_equal 4225, features["property_happy"]
  end

  test "maps Palace to 3000 happy" do
    features = build_feature_set(property: "Palace")
    assert_equal 3000, features["property_happy"]
  end

  test "defaults unknown property to 200" do
    features = build_feature_set(property: "Shack")
    assert_equal 200, features["property_happy"]
  end

  test "defaults nil property to 200" do
    features = build_feature_set(property: nil)
    assert_equal 200, features["property_happy"]
  end

  test "calculates real_age as age minus inactive days" do
    features = build_feature_set(age: 1000, last_action_timestamp: Time.now.to_i - 86_400)
    assert_equal 999, features["real_age"]
  end

  test "real_age floors at zero" do
    features = build_feature_set(age: 1000, last_action_timestamp: Time.now.to_i - (5000 * 86_400))
    assert_equal 0, features["real_age"]
  end

  test "uses full age when last_action_timestamp is nil" do
    features = build_feature_set(age: 1000, last_action_timestamp: nil)
    assert_equal 1000, features["real_age"]
  end

  test "maps timeplayed API name to useractivity column" do
    features = build_feature_set(personalstats: { "timeplayed" => 999_999 })
    assert_equal 999_999, features["useractivity"]
  end

  test "to_h returns all expected feature keys" do
    features = build_feature_set
    Recon::TrainingSample::FEATURE_COLUMNS.each do |col|
      assert features.to_h.key?(col), "Missing feature: #{col}"
    end
  end

  test "bracket accessor works" do
    features = build_feature_set(personalstats: { "xantaken" => 500 })
    assert_equal 500, features["xantaken"]
  end

  private

  def build_feature_set(personalstats: {}, age: 1000, level: 50, property: nil, last_action_timestamp: Time.now.to_i)
    profile = Recon::TornApi::Profile::ProfileData.new(
      age: age, level: level, property: property, last_action_timestamp: last_action_timestamp
    )
    Recon::FeatureSet.new(personalstats: personalstats, profile: profile)
  end
end
