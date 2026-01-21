module TornApi
  module Torn
    class Items < Base
      ENDPOINT = "v2/torn/items".freeze

      def fetch
        response = get(ENDPOINT, striptags: false)
        if response["items"].present?
          build_items(response["items"])
        else
          raise InvalidKeyError, "Torn API authentication failed: #{response}"
        end
      end

      private

      def build_items(items_data)
        items_data.map do |details|
          ::Torn::Item.new(torn_id: details["id"], name: details["name"], market_price: details["value"]["market_price"])
        end
      end
    end
  end
end
