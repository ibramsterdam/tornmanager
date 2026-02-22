module Api
  class CurrentWarController < ActionController::API
    before_action :require_api_key
    before_action :set_user

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

    private

    def require_api_key
      render json: { error: "API key is required" }, status: :bad_request if params[:api_key].blank?
    end

    def set_user
      @user = User.find_by(api_key: params[:api_key].to_s.strip)
      render json: { error: "Unknown API key. Please sign in first." }, status: :not_found unless @user
    end
  end
end
