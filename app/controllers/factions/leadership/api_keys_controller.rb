class Factions::Leadership::ApiKeysController < Factions::Leadership::BaseController
  def update
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting

    new_torn_key = params.dig(:faction_setting, :torn_api_key).presence
    new_tornstats_key = params.dig(:faction_setting, :tornstats_api_key).presence

    changes_made = false

    if new_torn_key
      begin
        key_info = TornApi::Key::Info.new(new_torn_key).fetch

        unless key_info.access.type == "Limited Access"
          return redirect_to faction_leadership_settings_path(@faction),
            alert: "Only Limited Access keys are allowed."
        end

        unless Current.user.admin? || key_info.user.id == Current.user.torn_id
          return redirect_to faction_leadership_settings_path(@faction), alert: "This API key does not belong to you."
        end

        @faction_setting.torn_api_key = new_torn_key
        @faction_setting.torn_api_access_type = key_info.access.type
        changes_made = true
      rescue TornApi::InvalidKeyError
        return redirect_to faction_leadership_settings_path(@faction), alert: "Invalid Torn API key."
      rescue TornApi::ApiError => e
        return redirect_to faction_leadership_settings_path(@faction), alert: "Could not validate Torn API key: #{e.message}"
      end
    end

    if new_tornstats_key
      @faction_setting.tornstats_api_key = new_tornstats_key
      changes_made = true
    end

    if !changes_made
      redirect_to faction_leadership_settings_path(@faction), notice: "No changes made."
    elsif @faction_setting.save
      redirect_to faction_leadership_settings_path(@faction), notice: "API keys saved successfully."
    else
      redirect_to faction_leadership_settings_path(@faction), alert: "Failed to save settings."
    end
  end

  def destroy
    setting = @faction.faction_setting

    unless setting
      return redirect_to faction_leadership_settings_path(@faction), alert: "No API keys configured."
    end

    case params[:key]
    when "torn"
      setting.update!(torn_api_key: nil, torn_api_access_type: nil)
      redirect_to faction_leadership_settings_path(@faction), notice: "Torn API key deleted."
    when "tornstats"
      setting.update!(tornstats_api_key: nil)
      redirect_to faction_leadership_settings_path(@faction), notice: "TornStats API key deleted."
    else
      redirect_to faction_leadership_settings_path(@faction), alert: "Unknown key type."
    end
  end
end
