class Factions::Leadership::SetupController < Factions::Leadership::BaseController
  skip_before_action :require_setup_completed
  skip_before_action :require_faction_leadership
  skip_before_action :require_api_keys_configured
  before_action :find_faction

  def show
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting
  end

  def update
    new_torn_key = params.dig(:faction_setting, :torn_api_key).presence
    new_tornstats_key = params.dig(:faction_setting, :tornstats_api_key).presence

    unless new_torn_key.present?
      return redirect_to faction_leadership_setup_path(@faction), alert: "Torn API key is required."
    end

    begin
      key_info = TornApi::Key::Info.new(new_torn_key).fetch

      unless key_info.access.type == "Limited Access"
        return redirect_to faction_leadership_setup_path(@faction),
          alert: "Only Limited Access keys are allowed. Please create a Limited Access key in your Torn settings."
      end

      unless key_info.access.faction == true
        return redirect_to faction_leadership_setup_path(@faction),
          alert: "This API key does not have faction access. Please enable faction access in your Torn API key settings."
      end

      unless Current.user.admin? || key_info.user.id == Current.user.torn_id
        return redirect_to faction_leadership_setup_path(@faction), alert: "This API key does not belong to you."
      end

      @faction.create_faction_setting! unless @faction.faction_setting

      torn_record = @faction.torn_api_key || @faction.build_torn_api_key
      torn_record.update!(
        key: new_torn_key,
        access_type: key_info.access.type,
        faction_access: key_info.access.faction == true
      )

      if new_tornstats_key.present?
        ts_record = @faction.tornstats_api_key || @faction.build_tornstats_api_key
        ts_record.update!(key: new_tornstats_key)
      end

      redirect_to faction_leadership_path(@faction), notice: "Faction configured successfully! You now have access to war tracking and analytics."
    rescue TornApi::InvalidKeyError
      redirect_to faction_leadership_setup_path(@faction), alert: "Invalid Torn API key."
    rescue TornApi::ApiError => e
      redirect_to faction_leadership_setup_path(@faction), alert: "Could not validate Torn API key: #{e.message}"
    end
  end
end
