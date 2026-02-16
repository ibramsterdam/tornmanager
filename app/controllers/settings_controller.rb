class SettingsController < ApplicationController
  REFRESH_COOLDOWN = 1.minute

  def index
    @sessions_count = Current.user.sessions.count
    @api_calls_count = Current.user.api_calls.count
    @payments_count = Current.user.sent_xanax_payments.count
    @faction_grants_count = Current.user.subscription_grants.count

    @subscribed = Current.user.subscribed?
    @days_remaining = calculate_days_remaining if @subscribed
    @subscription_progress = calculate_subscription_progress if @subscribed

    @last_refresh_at = session[:last_subscription_refresh_at]
    @can_refresh = can_refresh?
    @seconds_until_refresh = seconds_until_refresh
  end

  def purge_data
    Rails.logger.info "User #{Current.user.torn_id} (#{Current.user.name}) initiated data purge"

    Current.user.sessions.destroy_all
    Current.user.api_calls.destroy_all
    Current.user.update!(api_key: nil)

    Appsignal.increment_counter("user.data_purged", 1)

    Rails.logger.info "Data purge completed for user #{Current.user.torn_id}"

    terminate_session
    redirect_to root_path, notice: "All your collected data has been deleted and you've been signed out. Your subscription status has been preserved. You can log back in anytime using your Torn API key."
  end

  def refresh_subscription
    unless can_refresh?
      redirect_to settings_path, alert: "Please wait #{seconds_until_refresh} seconds before refreshing again."
      return
    end

    session[:last_subscription_refresh_at] = Time.current.to_i
    Daily::XanaxPaymentsJob.perform_now

    Appsignal.increment_counter("subscription.manual_refresh", 1)

    redirect_to settings_path, notice: "Subscription status refreshed! Check your subscription details above."
  rescue => e
    Rails.logger.error "Failed to refresh subscription for user #{Current.user.torn_id}: #{e.message}"
    Appsignal.increment_counter("subscription.refresh_failed", 1)
    Appsignal.send_error(e)
    redirect_to settings_path, alert: "Failed to refresh subscription status. Please try again later."
  end

  private

  def calculate_days_remaining
    (Current.user.subscription_expires_at.to_date - Date.current).to_i
  end

  def calculate_subscription_progress
    return 0 unless Current.user.subscribed?

    days_remaining = calculate_days_remaining
    total_days = 365

    percentage_remaining = [ (days_remaining.to_f / total_days * 100).round(1), 100 ].min
    100 - percentage_remaining
  end

  def can_refresh?
    return true unless session[:last_subscription_refresh_at]
    Time.current - Time.at(session[:last_subscription_refresh_at]) >= REFRESH_COOLDOWN
  end

  def seconds_until_refresh
    return 0 unless session[:last_subscription_refresh_at]
    remaining = REFRESH_COOLDOWN - (Time.current - Time.at(session[:last_subscription_refresh_at]))
    [ remaining.to_i, 0 ].max
  end
end
