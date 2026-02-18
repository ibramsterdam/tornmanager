module TornApi
  module Faction
    class RankedWars < Base
      attr_reader :faction_id

      def initialize(api_key, faction_id = nil)
        super(api_key)
        @faction_id = faction_id
      end

      def endpoint
        if faction_id
          "v2/faction/#{faction_id}/rankedwars"
        else
          "v2/faction/rankedwars"
        end
      end

      def fetch(limit: 20, offset: 0, sort: "DESC")
        response = get(endpoint, { limit: limit, offset: offset, sort: sort })
        response["rankedwars"] || []
      end

      # Fetch all wars (paginated)
      def fetch_all
        all_wars = []
        offset = 0
        limit = 100

        loop do
          wars = fetch(limit: limit, offset: offset)
          break if wars.empty?

          all_wars.concat(wars)
          offset += limit

          # Safety limit - fetch up to 1000 wars max
          break if offset > 1000
        end

        all_wars
      end
    end
  end
end
