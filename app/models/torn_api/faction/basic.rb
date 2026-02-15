module TornApi
  module Faction
    class Basic < Base
      attr_reader :torn_id

      def initialize(api_key, torn_id)
        super(api_key)
        @torn_id = torn_id
      end

      def endpoint
        "v2/faction/#{@torn_id}"
      end

      def fetch
        response = get(endpoint)
        if response["basic"].present?
          response["basic"]
        else
          raise InvalidKeyError, "Torn API authentication failed: #{response}"
        end
      end

      def name
        fetch["name"]
      end
    end
  end
end
