module Api
  class CurrentWarController < BaseController
    def show
      faction = @user.faction
      unless faction
        return render json: { error: "You are not a member of any faction." }, status: :unprocessable_entity
      end

      war_data = Rails.cache.read(faction.war_cache_key)

      if war_data
        render json: { war: war_data }
      else
        render json: { war: nil }
      end
    end
  end
end
