class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    api_key = params[:api_key].to_s.strip

    begin
      # First, validate the key access level
      key_info = TornApi::Key::Info.new(api_key).fetch

      unless key_info.access.type == "Limited Access"
        return redirect_to new_session_path, alert: "Please use a Limited Access API key. Your key has #{key_info.access.type}."
      end

      # Fetch profile using the validated key
      profile = TornApi::User::Profile.new(api_key).fetch

      return redirect_to new_session_path, alert: "Could not fetch profile from Torn API." unless profile

      torn_user = TornUser.find_or_create_by!(torn_id: profile.id) do |tu|
        tu.name = profile.name
        tu.level = profile.level
      end

      torn_user.update!(name: profile.name, level: profile.level)

      # Find or create user by API key (which is unique), then associate with torn_user
      user = User.find_or_create_by(api_key: api_key) do |u|
        u.torn_user_id = torn_user.id
      end

      # Update the torn_user association if it changed
      user.update!(torn_user_id: torn_user.id) if user.torn_user_id != torn_user.id

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
