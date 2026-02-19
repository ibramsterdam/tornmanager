module Api
  class SubscriptionsController < ActionController::API
    PAYMENT_CHECK_COOLDOWN = 5.minutes
    CACHE_KEY = "api:payment_check:last_run"

    def show
      api_key = params[:api_key].to_s.strip

      if api_key.blank?
        return render json: { error: "API key is required" }, status: :bad_request
      end

      user = User.find_by(api_key: api_key)

      unless user
        return render json: { error: "Unknown API key. Please sign in first." }, status: :not_found
      end

      if params[:refresh].present?
        unless check_payments!
          seconds = seconds_until_available
          return render json: {
            error: "Payment check was run recently. Try again in #{seconds} seconds."
          }, status: :too_many_requests
        end

        user.reload
      end

      render json: {
        subscription: {
          active: user.subscribed?,
          expires_at: user.subscription_expires_at&.iso8601
        }
      }, status: :ok
    rescue => e
      Rails.logger.error("API subscription check failed: #{e.class} - #{e.message}")
      render json: { error: "Could not check subscription status. Please try again later." }, status: :internal_server_error
    end

    private

    def check_payments!
      return false if rate_limited?

      Rails.cache.write(CACHE_KEY, Time.current, expires_in: PAYMENT_CHECK_COOLDOWN)
      Daily::XanaxPaymentsJob.perform_now
      true
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
