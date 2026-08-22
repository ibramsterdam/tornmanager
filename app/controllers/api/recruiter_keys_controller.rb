module Api
  class RecruiterKeysController < BaseController
    before_action :require_active_subscription
    rate_limit to: 10, within: 1.minute

    def create
      key = params[:key].to_s.strip
      return render json: { error: "API key is required" }, status: :bad_request if key.blank?

      info = TornApi::Key::Info.new(key).fetch
      unless info.access.type.to_s.match?(/public/i)
        return render json: { error: "Only Public access keys are accepted." }, status: :bad_request
      end

      basic = TornApi::User::Basic.new(key).fetch
      owner = User.find_by(torn_id: basic.id) || User.new(torn_id: basic.id)
      owner.assign_attributes(name: basic.name, level: basic.level)
      owner.save!

      record = owner.torn_api_key
      if record&.recruiter_fetch_allowed?
        return render json: { error: "A key from #{owner.name} [#{owner.torn_id}] is already in the pool." }, status: :conflict
      end

      if record
        record.update!(recruiter_fetch_allowed: true, submitted_by: @user)
      else
        record = owner.create_torn_api_key!(key: key, access_type: info.access.type, recruiter_fetch_allowed: true, submitted_by: @user)
      end

      render json: { key: key_json(record) }, status: :created
    rescue TornApi::InvalidKeyError
      render json: { error: "Invalid Torn API key" }, status: :bad_request
    end

    def index
      render json: { keys: pool_keys.map { |record| key_json(record) } }
    end

    def destroy
      record = pool_keys.joins(:user).find_by(users: { torn_id: params[:torn_id].to_i })
      return render json: { error: "Key not found." }, status: :not_found unless record

      record.update!(recruiter_fetch_allowed: false)
      head :no_content
    end

    private

    def pool_keys
      ApiKey.where(recruiter_fetch_allowed: true)
        .where("api_keys.submitted_by_id = ? OR api_keys.user_id = ?", @user.id, @user.id)
        .includes(:user)
    end

    def key_json(record)
      {
        owner_torn_id: record.user&.torn_id,
        owner_name: record.user&.name,
        access_type: record.access_type,
        mine: record.user_id == @user.id,
        added_at: record.updated_at.iso8601
      }
    end
  end
end
