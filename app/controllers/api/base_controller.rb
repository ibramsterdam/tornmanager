module Api
  class BaseController < ActionController::API
    before_action :require_api_key
    before_action :set_user

    private

    def require_api_key
      render json: { error: "API key is required" }, status: :bad_request if params[:api_key].blank?
    end

    def set_user
      @user = User.find_by_api_key(params[:api_key].to_s.strip)
      render json: { error: "Unknown API key. Please sign in first." }, status: :not_found unless @user
    end
  end
end
