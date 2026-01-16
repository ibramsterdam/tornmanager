class ProgressController < ApplicationController
  def index
    owned_stocks = TornApi::User::Stocks.new(Current.user.api_key).fetch
    @table_rows = Torn::Stock.money_rows(owned_stocks).sort_by { |row| row[:days_to_break_even].infinite? ? Float::INFINITY : row[:days_to_break_even] }
  end
end
