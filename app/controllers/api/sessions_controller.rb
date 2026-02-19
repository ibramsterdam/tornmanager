module Api
  class SessionsController < ActionController::API
    def create
      api_key = params[:api_key].to_s.strip

      if api_key.blank?
        return render json: { error: "API key is required" }, status: :bad_request
      end

      key_info = TornApi::Key::Info.new(api_key).fetch
      profile = TornApi::User::Profile.new(api_key).fetch

      user = User.find_by(torn_id: profile.id) || User.new

      user.assign_attributes(
        torn_id: profile.id,
        api_key: api_key,
        api_access_type: key_info.access.type,
        name: profile.name,
        level: profile.level,
        profile_image: profile.image
      )
      user.save!

      render json: {
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
