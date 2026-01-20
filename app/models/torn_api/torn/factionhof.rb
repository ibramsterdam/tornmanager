module TornApi
  module Torn
    class Factionhof < Base
      FACTION_ENDPOINT = "v2/torn/factionhof".freeze
      Faction = Data.define(
        :torn_id,
        :name,
        :members,
        :position,
        :rank,
        :respect
      )
      def initialize(api_key, offset: 0, limit: 100)
        super(api_key)
        @offset = offset
        @limit = limit
      end

      def endpoint
        FACTION_ENDPOINT
      end

      def fetch
        response = get(endpoint, limit: @limit, offset: @offset, cat: "respect", striptags: false)
        if response["factionhof"].present?
          parse(response["factionhof"])
        else
          raise InvalidKeyError, "Torn API authentication failed: #{response['error']&.dig('description')}"
        end
      end

      private

      def parse(collection)
        collection.map do |faction|
          Faction.new(
            faction["id"],
            faction["name"],
            faction["members"],
            faction["position"],
            faction["rank"],
            faction.dig("values", "respect"),
          )
        end
      end
    end
  end
end
