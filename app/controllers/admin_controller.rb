class AdminController < ActionController::Base
  before_action :authenticate_with_basic

  private

  def authenticate_with_basic
     http_basic_authenticate_with name: "admin", password: Rails.application.credentials.dig(:http_auth, :password)
  end
end
