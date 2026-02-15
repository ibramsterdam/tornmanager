class ProgressController < ApplicationController
  before_action :ensure_user_authenticated

  def index
    owned_stocks = TornApi::User::Stocks.new(Current.user.api_key, user: Current.user).fetch
    @table_rows = Torn::Stock.money_rows(owned_stocks).sort_by { |row| row[:days_to_break_even].infinite? ? Float::INFINITY : row[:days_to_break_even] }
  rescue TornApi::InvalidKeyError
    redirect_to new_session_path, alert: "Invalid or expired API key. Please sign in again."
  rescue TornApi::ApiError => e
    redirect_to root_path, alert: "Could not fetch stock data: #{e.message}"
  end

  private

  def ensure_user_authenticated
    unless Current.user&.api_key.present?
      redirect_to new_session_path, alert: "Please sign in to view your progress."
    end
  end
end
