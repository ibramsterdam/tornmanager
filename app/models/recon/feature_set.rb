class Recon::FeatureSet
  # Keys are our DB column names, values are Torn API stat names (when different)
  PERSONALSTAT_MAP = {
    "xantaken" => "xantaken",
    "energydrinkused" => "energydrinkused",
    "refills" => "refills",
    "daysbeendonator" => "daysbeendonator",
    "statenhancersused" => "statenhancersused",
    "boostersused" => "boostersused",
    "lsdtaken" => "lsdtaken",
    "revives" => "revives",
    "exttaken" => "exttaken",
    "victaken" => "victaken",
    "rehabs" => "rehabs",
    "highestbeaten" => "highestbeaten",
    "hospital" => "hospital",
    "jobpointsused" => "jobpointsused",
    "trainsreceived" => "trainsreceived",
    "attackswon" => "attackswon",
    "awards" => "awards",
    "useractivity" => "timeplayed",
    "networth" => "networth"
  }.freeze

  PERSONALSTAT_KEYS = PERSONALSTAT_MAP.keys.freeze
  API_STAT_NAMES = PERSONALSTAT_MAP.values.freeze

  # Fully upgraded property happy caps (with staff)
  # Ordered most expensive first for matching
  PROPERTY_HAPPY = {
    "Private Island" => 5025,
    "Castle" => 3475,
    "Palace" => 2550,
    "Ranch" => 1925,
    "Mansion" => 1725,
    "Penthouse" => 1150,
    "Villa" => 800,
    "Chalet" => 725,
    "Beach House" => 650,
    "Detached House" => 500,
    "Semi-Detached House" => 275,
    "Apartment" => 188,
    "Trailer" => 165,
    "Shack" => 100
  }.freeze

  DEFAULT_HAPPY = 100

  def self.build(personalstats:, profile:)
    features = {}

    PERSONALSTAT_MAP.each do |column, api_name|
      features[column] = personalstats[api_name] || 0
    end

    features["level"] = profile.level || 0
    features["property_happy"] = resolve_property_happy(profile.property)
    features["real_age"] = calculate_real_age(profile.age, profile.last_action_timestamp)

    add_engineered_features(features)

    features
  end

  def self.add_engineered_features(features)
    age = [ features["real_age"], 1 ].max.to_f
    xan = (features["xantaken"] || 0).to_f
    refills = (features["refills"] || 0).to_f
    edrink = (features["energydrinkused"] || 0).to_f
    se = (features["statenhancersused"] || 0).to_f
    boosters = (features["boostersused"] || 0).to_f

    total_energy = xan * 250 + refills * 150 + edrink * 100

    features["xan_per_day"] = xan / age
    features["refills_per_day"] = refills / age
    features["edrink_per_day"] = edrink / age
    features["se_per_day"] = se / age
    features["total_energy"] = total_energy
    features["energy_per_day"] = total_energy / age
    features["boosters_per_day"] = boosters / age
    features["has_se"] = se >= 3 ? 1.0 : 0.0
    features
  end

  def self.resolve_property_happy(property)
    return DEFAULT_HAPPY if property.nil?

    PROPERTY_HAPPY.find { |name, _| property.include?(name) }&.last || DEFAULT_HAPPY
  end

  def self.calculate_real_age(age, last_action_timestamp)
    age ||= 0
    return age if last_action_timestamp.nil?

    days_inactive = (Time.now - Time.at(last_action_timestamp)).to_i / 1.day
    [ age - days_inactive, 0 ].max
  end

  private_class_method :resolve_property_happy, :calculate_real_age
end
