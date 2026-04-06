class Factions::Leadership::ApiKeysController < Factions::Leadership::BaseController
  def update
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

        unless key_info.access.faction == true
          return redirect_to faction_leadership_settings_path(@faction),
            alert: "This API key does not have faction access. Please enable faction access in your Torn API key settings."
        end

        unless Current.user.admin? || key_info.user.id == Current.user.torn_id
          return redirect_to faction_leadership_settings_path(@faction), alert: "This API key does not belong to you."
        end

        torn_record = @faction.torn_api_key || @faction.build_torn_api_key
        torn_record.update!(
          key: new_torn_key,
          access_type: key_info.access.type,
          faction_access: key_info.access.faction == true
        )
        changes_made = true
      rescue TornApi::InvalidKeyError
        return redirect_to faction_leadership_settings_path(@faction), alert: "Invalid Torn API key."
      rescue TornApi::ApiError => e
        return redirect_to faction_leadership_settings_path(@faction), alert: "Could not validate Torn API key: #{e.message}"
      end
    end

    if new_tornstats_key
      ts_record = @faction.tornstats_api_key || @faction.build_tornstats_api_key
      ts_record.update!(key: new_tornstats_key)
      changes_made = true
    end

    if changes_made
      redirect_to faction_leadership_settings_path(@faction), notice: "API keys saved successfully."
    else
      redirect_to faction_leadership_settings_path(@faction), notice: "No changes made."
    end
  end

  def destroy
    case params[:key]
    when "torn"
      @faction.torn_api_key&.destroy!
      redirect_to faction_leadership_settings_path(@faction), notice: "Torn API key deleted."
    when "tornstats"
      @faction.tornstats_api_key&.destroy!
      redirect_to faction_leadership_settings_path(@faction), notice: "TornStats API key deleted."
    else
      redirect_to faction_leadership_settings_path(@faction), alert: "Unknown key type."
    end
  end
end
