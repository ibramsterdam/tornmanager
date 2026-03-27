class Recon::FeatureSet
  PERSONALSTAT_KEYS = %w[
    xantaken energydrinkused refills daysbeendonator
    statenhancersused boostersused lsdtaken revives exttaken victaken
    rehabs highestbeaten hospital jobpointsused trainsreceived
    attackswon awards useractivity networth
  ].freeze

  PROPERTY_HAPPY = {
    "Private Island" => 4225,
    "Palace" => 3000,
    "Castle" => 2700,
    "Ranch" => 2000,
    "Mansion" => 1500,
    "Villa" => 1000,
    "Penthouse" => 500
  }.freeze

  DEFAULT_HAPPY = 200

  def initialize(personalstats:, profile:)
    @personalstats = personalstats
    @profile = profile
  end

  def to_h
    @to_h ||= build
  end

  def [](key)
    to_h[key]
  end

  private

  def build
    features = {}

    PERSONALSTAT_KEYS.each do |key|
      features[key] = @personalstats[key] || 0
    end

    features["level"] = @profile.level || 0
    features["property_happy"] = resolve_property_happy(@profile.property)
    features["real_age"] = calculate_real_age(@profile.age, @profile.last_action_timestamp)

    features
  end

  def resolve_property_happy(property)
    return DEFAULT_HAPPY if property.nil?

    PROPERTY_HAPPY.find { |name, _| property.include?(name) }&.last || DEFAULT_HAPPY
  end

  def calculate_real_age(age, last_action_timestamp)
    age ||= 0
    return age if last_action_timestamp.nil?

    days_inactive = ((Time.now.to_i - last_action_timestamp) / 86_400.0).round
    [ age - days_inactive, 0 ].max
  end
end
