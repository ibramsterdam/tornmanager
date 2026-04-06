module Api
  class SubscriptionsController < ActionController::API
    PAYMENT_CHECK_COOLDOWN = 5.minutes
    CACHE_KEY = "api:payment_check:last_run"

    before_action :require_api_key
    before_action :set_user

    def show
      refresh_payments! if params[:refresh].present?
      return if performed?

      render json: {
        subscription: {
          active: @user.subscribed?,
          expires_at: @user.subscription_expires_at&.iso8601
        }
      }
    end

    private

    def require_api_key
      render json: { error: "API key is required" }, status: :bad_request if params[:api_key].blank?
    end

    def set_user
      @user = User.find_by_api_key(params[:api_key].to_s.strip)
      render json: { error: "Unknown API key. Please sign in first." }, status: :not_found unless @user
    end

    def refresh_payments!
      if rate_limited?
        render json: { error: "Payment check was run recently. Try again in #{seconds_until_available} seconds." },
          status: :too_many_requests
      else
        Rails.cache.write(CACHE_KEY, Time.current, expires_in: PAYMENT_CHECK_COOLDOWN)
        Daily::XanaxPaymentsJob.perform_now
        @user.reload
      end
    end

    def rate_limited?
      Rails.cache.exist?(CACHE_KEY)
    end

    def seconds_until_available
      last_run = Rails.cache.read(CACHE_KEY)
      return 0 unless last_run

      remaining = PAYMENT_CHECK_COOLDOWN - (Time.current - last_run)
      [ remaining.to_i, 0 ].max
    end
  end
end
