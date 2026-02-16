module TornApi
  module User
    class HistoricalPersonalStat < Base
      attr_reader :torn_id

      def initialize(api_key, torn_id)
        super(api_key)
        @torn_id = torn_id
      end

      def fetch(stat_name, timestamp)
        endpoint = "v2/user/#{torn_id}/personalstats"
        params = { stat: stat_name, timestamp: timestamp }

        response = get(endpoint, params)

        if response["personalstats"]&.any?
          response.dig("personalstats", 0, "value")
        else
          nil
        end
      end
    end
  end
end
