module Api
  class WarsController < ActionController::API
    def show
      api_key = params[:api_key].to_s.strip
      torn_ids = Array(params[:torn_ids]).map(&:to_i).reject(&:zero?)
      enemy_faction_id = params[:enemy_faction_id].to_s.strip.presence

      if api_key.blank?
        return render json: { error: "API key is required" }, status: :bad_request
      end

      if torn_ids.empty?
        return render json: { error: "torn_ids is required" }, status: :bad_request
      end

      user = User.find_by(api_key: api_key)
      unless user
        return render json: { error: "Unknown API key. Please sign in first." }, status: :not_found
      end

      faction = user.faction
      unless faction
        return render json: { error: "You are not a member of any faction." }, status: :unprocessable_entity
      end

      setting = faction.faction_setting
      unless setting&.keys_configured?
        return render json: { error: "Faction API keys not configured. Ask your faction leader to set them up on tornmanager.com." }, status: :unprocessable_entity
      end

      # Look up spy reports
      spy_reports = faction.spy_reports.for_targets(torn_ids).index_by(&:torn_id)

      # Live fetch enemy status from Torn API
      members_status = {}
      if enemy_faction_id.present?
        members_status = fetch_enemy_status(setting.torn_api_key, enemy_faction_id)
      end

      # Build response
      members = {}
      torn_ids.each do |torn_id|
        spy = spy_reports[torn_id]
        status = members_status[torn_id]

        if spy || status
          members[torn_id.to_s] = build_member_data(torn_id, spy, status)
        else
          members[torn_id.to_s] = nil
        end
      end

      render json: { members: members }, status: :ok
    rescue => e
      Rails.logger.error("API war endpoint failed: #{e.class} - #{e.message}")
      render json: { error: "Could not fetch war data. Please try again later." }, status: :internal_server_error
    end

    private

    def fetch_enemy_status(torn_api_key, enemy_faction_id)
      members = TornApi::Faction::Members.new(torn_api_key, enemy_faction_id).fetch
      members.each_with_object({}) do |member, hash|
        hash[member.id] = member
      end
    rescue TornApi::ApiError => e
      Rails.logger.error("War live fetch failed for faction #{enemy_faction_id}: #{e.class} - #{e.message}")
      {}
    end

    def build_member_data(torn_id, spy, status)
      data = { torn_id: torn_id }

      if status
        data[:name] = status.name
        data[:level] = status.level

        state = status.status_state
        if state && state != "Okay"
          status_data = { state: state }
          status_data[:description] = status.status_description if status.status_description.present?

          # status_until is a Unix timestamp from Torn API; 0 means no timer
          if status.status_until.present? && status.status_until.to_i > 0
            status_data[:until] = Time.at(status.status_until.to_i).iso8601
          end

          data[:status] = status_data
        else
          data[:status] = { state: "Okay" }
        end
      end

      if spy
        data[:stats] = spy.stats_hash
        data[:stats_timestamp] = spy.spied_at&.iso8601
      end

      data
    end
  end
end
