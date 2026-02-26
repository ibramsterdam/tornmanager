module Factions
  class SetupController < ApplicationController
    def show
      torn_faction_id = session[:torn_faction_id]

      unless torn_faction_id.present?
        redirect_to stocks_path, alert: "No faction found for your account."
        return
      end

      # If someone else already set up this faction, assign the user and go to dashboard
      existing_faction = Faction.find_by(torn_id: torn_faction_id)
      if existing_faction
        Current.user.update!(faction_id: existing_faction.id) unless Current.user.faction_id == existing_faction.id
        redirect_to faction_path(existing_faction)
        return
      end

      @torn_faction_id = torn_faction_id
      @api_key_prefill = Current.user.has_limited_access? ? Current.user.api_key : nil
    end

    def create
      torn_faction_id = session[:torn_faction_id]
      api_key = params[:api_key].to_s.strip

      unless torn_faction_id.present?
        redirect_to stocks_path, alert: "No faction found for your account."
        return
      end

      # Validate the API key
      begin
        key_info = TornApi::Key::Info.new(api_key).fetch
      rescue TornApi::InvalidKeyError
        @torn_faction_id = torn_faction_id
        @error = "Invalid API key. Please check and try again."
        return render :show, status: :unprocessable_entity
      end

      # Must be Limited Access
      unless key_info.access.type == "Limited Access"
        @torn_faction_id = torn_faction_id
        @error = "This key is #{key_info.access.type}. A Limited Access key is required."
        return render :show, status: :unprocessable_entity
      end

      # Must belong to the current user
      unless key_info.user.id == Current.user.torn_id
        @torn_faction_id = torn_faction_id
        @error = "This API key does not belong to you."
        return render :show, status: :unprocessable_entity
      end

      # Must be for the correct faction
      unless key_info.user.faction_id == torn_faction_id
        @torn_faction_id = torn_faction_id
        @error = "This API key is for a different faction."
        return render :show, status: :unprocessable_entity
      end

      # Race condition: faction may have been created between show and create
      faction = Faction.find_by(torn_id: torn_faction_id)

      unless faction
        # Fetch faction name from Torn API
        begin
          faction_data = TornApi::Faction::Basic.new(api_key, torn_faction_id).fetch
          faction_name = faction_data["name"]
        rescue StandardError => e
          @torn_faction_id = torn_faction_id
          @error = "Could not fetch faction info: #{e.message}"
          return render :show, status: :unprocessable_entity
        end

        faction = Faction.create!(torn_id: torn_faction_id, name: faction_name)
      end

      # Create faction setting with the API key
      setting = faction.faction_setting || faction.build_faction_setting
      setting.update!(torn_api_key: api_key, torn_api_access_type: "Limited Access")

      # Assign user to faction
      Current.user.update!(faction_id: faction.id)

      # Grant leadership access to the setup user
      faction.faction_whitelists.find_or_create_by!(user: Current.user)

      # Sync faction members (synchronous — fast, single API call)
      SyncFactionMembersJob.perform_now(faction.id)

      # Queue background jobs
      BackfillRankedWarsJob.perform_later(faction.id)
      BackfillPersonalStatsJob.perform_later(
        faction.id,
        PersonalStatSnapshot.tracking_start_date.to_s,
        Date.yesterday.to_s
      )

      # Clear the session flag
      session.delete(:torn_faction_id)

      redirect_to faction_path(faction), notice: "Your faction has been set up. Welcome to TornManager!"
    end
  end
end
