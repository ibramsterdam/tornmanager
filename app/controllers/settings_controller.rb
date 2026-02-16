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

    load_api_key_info
  end

  def api_key_card
    load_api_key_info
    render partial: "api_key_card"
  end

  def update_api_key
    new_api_key = params[:api_key]&.strip

    if new_api_key.blank?
      render json: { success: false, message: "API key cannot be blank." }
      return
    end

    if new_api_key == Current.user.api_key
      render json: { success: false, message: "This is already your current API key." }
      return
    end

    begin
      # Validate the new API key with Torn API (track the request)
      key_info = TornApi::Key::Info.new(new_api_key, user: Current.user).fetch

      # Don't allow Full Access keys
      if key_info.access.type == "Full Access"
        render json: { success: false, message: "Full Access keys are not allowed. Please use a Limited Access key instead." }
        return
      end

      # Verify the key belongs to this user (track the request)
      profile = TornApi::User::Profile.new(new_api_key, user: Current.user).fetch

      if profile.id != Current.user.torn_id
        render json: { success: false, message: "This API key belongs to a different user." }
        return
      end

      # Update the user's API key and access type
      Current.user.update!(
        api_key: new_api_key,
        api_access_type: key_info.access.type
      )

      Appsignal.increment_counter("user.api_key_updated", 1)

      render json: { success: true, message: "API key updated! Access level: #{key_info.access.type}", access_type: key_info.access.type }
    rescue TornApi::InvalidKeyError => e
      Rails.logger.error "Invalid API key for user #{Current.user.torn_id}: #{e.message}"
      render json: { success: false, message: "Invalid API key." }
    rescue TornApi::ApiError => e
      Rails.logger.error "API error updating key for user #{Current.user.torn_id}: #{e.message}"
      render json: { success: false, message: "Torn API error: #{e.message}" }
    rescue => e
      Rails.logger.error "Failed to update API key for user #{Current.user.torn_id}: #{e.class} - #{e.message}"
      Appsignal.send_error(e)
      render json: { success: false, message: "Failed to update API key. Please try again later." }
    end
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

  def export_data
    user = Current.user

    export = {
      exported_at: Time.current.iso8601,
      user: {
        torn_id: user.torn_id,
        name: user.name,
        level: user.level,
        profile_image: user.profile_image,
        api_access_type: user.api_access_type,
        subscription_expires_at: user.subscription_expires_at&.iso8601,
        created_at: user.created_at.iso8601,
        updated_at: user.updated_at.iso8601
      },
      sessions: user.sessions.map do |session|
        {
          ip_address: session.ip_address,
          user_agent: session.user_agent,
          created_at: session.created_at.iso8601
        }
      end,
      api_calls: user.api_calls.map do |call|
        {
          endpoint: call.endpoint,
          selections: call.selections,
          status: call.status,
          response_time_ms: call.response_time,
          error_message: call.error_message,
          created_at: call.created_at.iso8601
        }
      end
    }

    Appsignal.increment_counter("user.data_exported", 1)

    send_data export.to_json,
              filename: "tornmanager-data-#{user.torn_id}-#{Date.current}.json",
              type: "application/json",
              disposition: "attachment"
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

  def mask_api_key(api_key)
    return "Not set" if api_key.blank?
    "#{api_key[0..3]}********#{api_key[-4..]}"
  end

  def load_api_key_info
    @api_key_masked = mask_api_key(Current.user.api_key)
    @api_access_type = Current.user.api_access_type || "Unknown"
    @has_limited_access = Current.user.has_limited_access?
  end
end
