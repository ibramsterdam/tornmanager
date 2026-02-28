class Factions::LeadershipController < Factions::Leadership::BaseController
  include FactionHelper

  skip_before_action :require_setup_completed, only: [ :setup, :complete_setup ]
  skip_before_action :require_faction_leadership, only: [ :setup, :complete_setup ]
  skip_before_action :require_api_keys_configured, except: [ :show ]
  before_action :find_faction, only: [ :setup, :complete_setup ]

  def show
    load_wars_data
    load_spy_stats_data
    load_settings_data
    load_data_coverage
    load_api_peak_rate
  end

  def setup
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting
  end

  def complete_setup
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting

    new_torn_key = params.dig(:faction_setting, :torn_api_key).presence
    new_tornstats_key = params.dig(:faction_setting, :tornstats_api_key).presence

    unless new_torn_key.present?
      return redirect_to setup_faction_leadership_path(@faction), alert: "Torn API key is required."
    end

    begin
      key_info = TornApi::Key::Info.new(new_torn_key).fetch

      unless key_info.access.type == "Limited Access"
        return redirect_to setup_faction_leadership_path(@faction),
          alert: "Only Limited Access keys are allowed. Please create a Limited Access key in your Torn settings."
      end

      unless Current.user.admin? || key_info.user.id == Current.user.torn_id
        return redirect_to setup_faction_leadership_path(@faction), alert: "This API key does not belong to you."
      end

      @faction_setting.torn_api_key = new_torn_key
      @faction_setting.torn_api_access_type = key_info.access.type

      if new_tornstats_key.present?
        @faction_setting.tornstats_api_key = new_tornstats_key
      end

      @faction_setting.save!

      redirect_to faction_leadership_path(@faction), notice: "Faction configured successfully! You now have access to war tracking and analytics."
    rescue TornApi::InvalidKeyError
      redirect_to setup_faction_leadership_path(@faction), alert: "Invalid Torn API key."
    rescue TornApi::ApiError => e
      redirect_to setup_faction_leadership_path(@faction), alert: "Could not validate Torn API key: #{e.message}"
    end
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
