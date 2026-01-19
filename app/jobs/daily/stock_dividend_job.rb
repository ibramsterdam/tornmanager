module Daily
  class StockDividendJob < ApplicationJob
    queue_as :default

    def perform(*args)
      stocks = TornApi::Torn::Stocks.new(api_key).fetch
      items = Torn::Item.money_makers.index_by(&:torn_id)

      stocks.each do |fetched_stock|
        stock = Torn::Stock.find_by(torn_id: fetched_stock.torn_id)
        item = items[Torn::Stock::ACRONYM_TO_TORN_ITEM_ID[stock.acronym]]
        item_market_price = item&.market_price || 0
        dividend_value = calculate_dividend_value(fetched_stock.dividend_description, item_market_price)

        stock.update!(dividend_value:)
      end
    end

    private

    def calculate_dividend_value(description, item_market_price)
      if description.match(/\$\d+(,\d+)*(\.\d+)?/)
        description.delete("$,").to_i
      elsif description.match(/^\d+\s?x/i)
        item_market_price.to_i
      elsif description.include?("points")
        average_market_price * 100
      else
        0
      end
    end

    def average_market_price
      market_data = TornApi::Market.new(api_key).fetch
      return 0 if market_data.blank?

      costs = market_data.values.map { |point_data| point_data["cost"] }
      return 0 if costs.empty?

      costs.sum / costs.size
    end

    def api_key
      api_key ||=Rails.application.credentials.dig(:bram, :api_key)
    end
  end
end
