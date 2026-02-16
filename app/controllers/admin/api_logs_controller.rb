module Admin
  class ApiLogsController < ApplicationController
    before_action :require_admin

    def index
      owner_api_key = OwnerCredentials.api_key
      admin_user = User.find_by(torn_id: 2728237)

      @api_logs = ApiCall
        .where(api_key: owner_api_key)
        .where(user_id: admin_user&.id)
        .recent
        .limit(500)

      @total_calls = @api_logs.count
      @successful_calls = @api_logs.successful.count
      @failed_calls = @api_logs.failed.count
      @avg_response_time = @api_logs.where.not(response_time: nil).average(:response_time)&.round(0)

      @calls_today = ApiCall
        .where(api_key: owner_api_key)
        .where(user_id: admin_user&.id)
        .today
        .count

      @calls_last_24h = ApiCall
        .where(api_key: owner_api_key)
        .where(user_id: admin_user&.id)
        .last_24_hours
        .count
    end
  end
end
