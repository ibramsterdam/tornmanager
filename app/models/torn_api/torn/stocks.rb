module TornApi
  module Torn
    class Stocks < Base
      ENDPOINT = "v2/torn/stocks".freeze

      def fetch
        response = get(ENDPOINT, striptags: false)
        if response["stocks"].present?
          build_stocks(response["stocks"])
        else
          raise InvalidKeyError, "Torn API authentication failed: #{response['error']&.dig('description')}"
        end
      end

      private

      def build_stocks(data)
        data.map do |_, details|
          ::Torn::Stock.new(
            torn_id: details["stock_id"],
            name: details["name"],
            acronym: details["acronym"],
            current_price: details["current_price"],
            dividend_frequency: details["benefit"]["frequency"],
            dividend_requirement: details["benefit"]["requirement"],
            dividend_description: details["benefit"]["description"],
          )
        end
      end
    end
  end
end
