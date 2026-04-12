module TornApi
  module Torn
    class Stocks < Base
      ENDPOINT = "v2/torn/stocks".freeze

      def fetch
        response = get(ENDPOINT, { striptags: false })
        if response["stocks"].present?
          build_stocks(response["stocks"])
        else
          raise ApiError, "No stocks data returned: #{response}"
        end
      end

      private

      def build_stocks(data)
        data.map do |details|
          ::Torn::Stock.new(
            torn_id: details["id"],
            name: details["name"],
            acronym: details["acronym"],
            current_price: details.dig("market", "price"),
            dividend_frequency: details.dig("bonus", "frequency"),
            dividend_requirement: details.dig("bonus", "requirement"),
            dividend_description: details.dig("bonus", "description"),
          )
        end
      end
    end
  end
end
