module TornApi
  module User
    class HistoricalPersonalStat < Base
      attr_reader :torn_id

      def initialize(api_key, torn_id)
        super(api_key)
        @torn_id = torn_id
      end

      def fetch(stat_names, timestamp)
        endpoint = "v2/user/#{torn_id}/personalstats"
        stat_param = Array(stat_names).join(",")
        params = { stat: stat_param, timestamp: timestamp }

        response = get(endpoint, params)

        if response["personalstats"]&.any?
          if stat_names.is_a?(Array)
            response["personalstats"].each_with_object({}) do |stat, hash|
              hash[stat["name"]] = stat["value"]
            end
          else
            response.dig("personalstats", 0, "value")
          end
        else
          nil
        end
      end
    end
  end
end
