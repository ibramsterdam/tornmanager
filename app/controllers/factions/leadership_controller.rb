class Factions::LeadershipController < Factions::Leadership::BaseController
  include FactionHelper

  skip_before_action :require_api_keys_configured, only: [ :war_data ]

  def show
    load_wars_data
    load_spy_stats_data
    load_settings_data
    load_data_coverage
    load_api_peak_rate
    load_activity_data
    load_armory_stats
  end

  def load_armory_stats
    api_key = @faction.torn_api_key&.key
    return unless api_key

    stats = Rails.cache.fetch("armory_stats/#{@faction.id}", expires_in: 10.minutes) do
      response = TornApi::Faction::Armory.new(api_key).fetch
      items = (response["weapons"] || []) + (response["armor"] || [])
      total_loaned = items.sum { |i| i["loaned"] || 0 }
      { total_loaned: total_loaned }
    end

    @armory_loaned_count = stats[:total_loaned]
  rescue TornApi::ApiError, TornApi::InvalidKeyError
    @armory_loaned_count = nil
  end

  def war_data
    war_data = Rails.cache.read(@faction.war_cache_key)

    if war_data
      render json: war_data
    else
      render json: {}, status: :no_content
    end
  end
end
