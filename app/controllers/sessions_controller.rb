class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    api_key = params[:api_key].to_s.strip

    begin
      profile = TornApi::User::Profile.new(api_key).fetch
      if user = User.find_by(torn_id: profile["id"])
        start_new_session_for user
        redirect_to after_authentication_url
      else
        # user = User.upsert_from_torn_profile!(profile, api_key)
        redirect_to new_session_path, alert: "Currently not accepting anyone"
      end
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
    redirect_to new_session_path, status: :see_other
  end
end
