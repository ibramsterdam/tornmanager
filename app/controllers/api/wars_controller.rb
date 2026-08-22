module Api
  class WarsController < BaseController
    def show
      torn_ids = Array(params[:torn_ids]).map(&:to_i).reject(&:zero?)
      enemy_faction_id = params[:enemy_faction_id].to_s.strip.presence

      if torn_ids.empty?
        return render json: { error: "torn_ids is required" }, status: :bad_request
      end

      faction = @user.faction
      unless faction
        return render json: { error: "You are not a member of any faction." }, status: :unprocessable_entity
      end

      unless faction.torn_api_key.present?
        return render json: { error: "Faction API keys not configured. Ask your faction leader to set them up on tornmanager.com." }, status: :unprocessable_entity
      end

      spy_reports = faction.spy_reports.for_targets(torn_ids).index_by(&:torn_id)

      members_status = {}
      if enemy_faction_id.present?
        members_status = fetch_enemy_status(faction.torn_api_key.key, enemy_faction_id)
      end

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
