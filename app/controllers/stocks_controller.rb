class StocksController < ApplicationController
  before_action :ensure_user_authenticated

  def index
    @has_limited_access = Current.user.has_limited_access?

    owned_stocks = @has_limited_access ? TornApi::User::Stocks.new(Current.user.api_key).fetch : []
    @table_rows = Torn::Stock.money_rows(owned_stocks).sort_by do |row|
      row[:days_to_break_even].infinite? ? Float::INFINITY : row[:days_to_break_even]
    end
  rescue TornApi::InvalidKeyError
    redirect_to new_session_path, alert: "Invalid or expired API key. Please sign in again."
  rescue TornApi::ApiError => e
    redirect_to root_path, alert: "Could not fetch stock data: #{e.message}"
  end

  private

  def ensure_user_authenticated
    unless Current.user&.api_key.present?
      redirect_to new_session_path, alert: "Please sign in to view stocks."
    end
  end
end
