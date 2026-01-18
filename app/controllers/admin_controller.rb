class AdminController < ActionController::Base
  before_action :authenticate_with_basic

  private

  def authenticate_with_basic
    authenticate_or_request_with_http_basic do |username, password|
      username == Rails.application.credentials.dig(:mission_control, :http_basic_auth_user) &&
        password == Rails.application.credentials.dig(:mission_control, :http_basic_auth_password)
    end
  end
end
