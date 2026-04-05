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
