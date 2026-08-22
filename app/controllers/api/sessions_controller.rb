module Api
  class SessionsController < ActionController::API
    def create
      api_key = params[:api_key].to_s.strip

      if api_key.blank?
        return render json: { error: "API key is required" }, status: :bad_request
      end

      key_info = TornApi::Key::Info.new(api_key).fetch

      if key_info.access.type == "Full Access"
        return render json: { error: "Full Access keys are not allowed. Please use a Public or Limited Access key instead." }, status: :bad_request
      end

      profile = TornApi::User::Profile.new(api_key).fetch

      user = User.find_by(torn_id: profile.id) || User.new

      if user.persisted? && user.banned?
        return render json: { error: user.ban_message, suspended: true }, status: :forbidden
      end

      user.assign_attributes(
        torn_id: profile.id,
        name: profile.name,
        level: profile.level,
        profile_image: profile.image
      )
      user.save!
      user.set_api_key!(api_key, key_info.access.type)
      user.regenerate_api_token if user.api_token.blank?

      render json: {
        token: user.api_token,
        user: {
          torn_id: user.torn_id,
          name: user.name,
          level: user.level,
          profile_image: user.profile_image
        }
      }, status: :ok

    rescue TornApi::InvalidKeyError
      render json: { error: "Invalid Torn API key" }, status: :bad_request
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("API user upsert failed: #{e.record.errors.full_messages}")
      render json: { error: "Could not create user profile" }, status: :bad_request
    rescue => e
      Rails.logger.error("Unexpected API login error: #{e.class} - #{e.message}")
      render json: { error: "Unexpected error. Please try again." }, status: :bad_request
    end
  end
end
