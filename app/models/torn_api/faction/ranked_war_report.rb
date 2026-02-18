module TornApi
  module Faction
    class RankedWarReport < Base
      attr_reader :war_id

      def initialize(api_key, war_id)
        super(api_key)
        @war_id = war_id
      end

      def endpoint
        "v2/faction/#{war_id}/rankedwarreport"
      end

      def fetch
        response = get(endpoint)
        response["rankedwarreport"]
      end
    end
  end
end
