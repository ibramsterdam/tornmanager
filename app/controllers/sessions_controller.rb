class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    api_key = params[:api_key].to_s.strip

    begin
      key_info = TornApi::Key::Info.new(api_key).fetch

      unless key_info.access.type == "Limited Access"
        Appsignal.increment_counter("auth.login_failed", 1, { reason: "wrong_key_type" })
        return redirect_to new_session_path, alert: "Please use a Limited Access API key. Your key has #{key_info.access.type}."
      end

      profile = TornApi::User::Profile.new(api_key).fetch

      if profile.nil?
        Appsignal.increment_counter("auth.login_failed", 1, { reason: "profile_fetch_failed" })
        return redirect_to new_session_path, alert: "Could not fetch profile from Torn API."
      end

      user = User.find_by(torn_id: profile.id) || User.new

      user.assign_attributes(
        torn_id: profile.id,
        api_key: api_key,
        name: profile.name,
        level: profile.level,
        profile_image: profile.image
      )
      user.save!

      start_new_session_for user

      Appsignal.increment_counter("auth.login_success", 1)

      redirect_to after_authentication_url
    rescue TornApi::InvalidKeyError
      Appsignal.increment_counter("auth.login_failed", 1, { reason: "invalid_key" })
      redirect_to new_session_path, alert: "Invalid Torn API key."
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("User upsert failed: #{e.record.errors.full_messages}")
      Appsignal.increment_counter("auth.login_failed", 1, { reason: "user_save_failed" })
      redirect_to new_session_path, alert: "Could not create user profile."
    rescue => e
      Rails.logger.error("Unexpected login error: #{e.class} - #{e.message}")
      Appsignal.increment_counter("auth.login_failed", 1, { reason: "unexpected_error" })
      Appsignal.send_error(e)
      redirect_to new_session_path, alert: "Unexpected error. Please try again."
    end
  end

  def destroy
    Appsignal.increment_counter("auth.logout", 1)
    terminate_session
    redirect_to root_path, status: :see_other
  end
end
