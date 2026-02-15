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
        return redirect_to new_session_path, alert: "Please use a Limited Access API key. Your key has #{key_info.access.type}."
      end

      user = User.find_by(api_key: api_key) || User.new

      profile = TornApi::User::Profile.new(api_key, user: user).fetch

      return redirect_to new_session_path, alert: "Could not fetch profile from Torn API." unless profile

      user.assign_attributes(
        torn_id: profile.id,
        api_key: api_key,
        name: profile.name,
        level: profile.level,
        profile_image: profile.image
      )
      user.save!

      start_new_session_for user
      redirect_to after_authentication_url
    rescue TornApi::InvalidKeyError
      redirect_to new_session_path, alert: "Invalid Torn API key."
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("User upsert failed: #{e.record.errors.full_messages}")
      redirect_to new_session_path, alert: "Could not create user profile."
    rescue => e
      Rails.logger.error("Unexpected login error: #{e.class} - #{e.message}")
      redirect_to new_session_path, alert: "Unexpected error. Please try again."
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end
end
