module Api
  module TmCompany
    class SessionsController < ActionController::API
      rate_limit to: 10, within: 3.minutes, with: -> { render json: { error: "Too many sign in attempts. Try again in a few minutes." }, status: :too_many_requests }

      LIMITED_KEY_REQUIRED = "TM Company needs a Limited access key. Public and Full access keys are not accepted.".freeze
      DIRECTOR_REQUIRED = "Only company directors can use TM Company. This key belongs to someone who does not direct a company.".freeze

      def create
        api_key = params[:api_key].to_s.strip
        return reject("API key is required") if api_key.blank?

        info = TornApi::Key::Info.new(api_key).fetch
        return reject(LIMITED_KEY_REQUIRED) unless limited?(info.access)

        job = TornApi::User::Job.new(api_key).fetch
        return reject(DIRECTOR_REQUIRED) unless job.director?

        profile = TornApi::User::Profile.new(api_key).fetch
        user = User.find_by(torn_id: profile.id) || User.new

        if user.persisted? && user.banned?
          return render json: { error: user.ban_message, suspended: true }, status: :forbidden
        end

        if user.company_access_disabled?
          return render json: { error: "TM Company access has been turned off for your account." }, status: :forbidden
        end

        user.assign_attributes(
          torn_id: profile.id,
          name: profile.name,
          level: profile.level,
          profile_image: profile.image,
          company_id: job.company_id,
          company_director: true
        )
        user.save!
        user.set_company_api_key!(api_key, info.access.type)
        user.regenerate_api_token if user.api_token.blank?

        render json: {
          token: user.api_token,
          user: { torn_id: user.torn_id, name: user.name, level: user.level, profile_image: user.profile_image },
          company: { id: job.company_id, name: job.company_name, type_id: job.company_type_id, rating: job.rating }
        }
      rescue TornApi::InvalidKeyError
        reject("Invalid Torn API key")
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("TM Company sign in failed: #{e.record.errors.full_messages}")
        reject("Could not create user profile")
      end

      private

      def limited?(access)
        access.type == "Limited Access" || (access.type == "Custom" && access.company)
      end

      def reject(message)
        render json: { error: message }, status: :bad_request
      end
    end
  end
end
