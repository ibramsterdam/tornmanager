module TornApi
  module Torn
    class ItemDetails < Base
      def initialize(api_key, uid)
        super(api_key)
        @uid = uid
      end

      def endpoint
        "v2/torn/#{@uid}/itemdetails"
      end

      def fetch
        response = get(endpoint, { striptags: false })
        parse(response["itemdetails"])
      end

      private

      def parse(details)
        return nil unless details

        stats = details["stats"] || {}
        {
          id: details["id"],
          name: details["name"],
          damage: stats["damage"],
          accuracy: stats["accuracy"],
          armor: stats["armor"],
          quality: stats["quality"],
          rarity: details["rarity"],
          bonuses: details["bonuses"] || []
        }
      end
    end
  end
end
