module Api
  class BaseController < ActionController::API
    before_action :require_token
    before_action :set_user
    before_action :reject_banned

    private

    def require_token
      render json: { error: "Session token is required. Please sign in again." }, status: :unauthorized if bearer_token.blank?
    end

    def set_user
      @user = User.find_by(api_token: bearer_token)
      render json: { error: "Unknown session. Please sign in again." }, status: :unauthorized unless @user
    end

    def reject_banned
      return unless @user&.banned?

      render json: { error: @user.ban_message, suspended: true }, status: :forbidden
    end

    def require_active_subscription
      return if @user.subscribed?

      render json: { error: "An active subscription is required.", subscription_required: true }, status: :forbidden
    end

    def bearer_token
      @bearer_token ||= request.headers["Authorization"].to_s[/\ABearer (.+)\z/, 1].to_s.strip
    end
  end
end
