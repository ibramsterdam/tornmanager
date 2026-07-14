module TornApi
  module User
    class PersonalStats < Base
      attr_reader :torn_id, :timestamp, :stat_batch

      def initialize(api_key, torn_id, timestamp: nil, stat_batch: nil)
        super(api_key)
        @torn_id = torn_id
        @timestamp = timestamp
        @stat_batch = stat_batch || ::PersonalStatSnapshot::TRACKED_STATS
      end

      def endpoint
        "v2/user/#{@torn_id}/personalstats"
      end

      def fetch
        stat_names = stat_batch.keys.join(",")
        params = { stat: stat_names }
        params[:timestamp] = timestamp if timestamp

        response = get(endpoint, params)

        if response["personalstats"].present? || response["personalstats"].is_a?(Array)
          parse_personalstats(response["personalstats"], stat_batch)
        else
          # Torn intermittently returns a nil payload around the nightly
          # stats-cache rebuild — retryable, not fatal.
          raise TransientError, "No personal stats data returned: #{response}"
        end
      end

      private

      def parse_personalstats(stats, requested_stats)
        stats_hash = stats.each_with_object({}) do |stat, hash|
          hash[stat["name"]] = stat["value"]
        end

        response_timestamp = stats.first&.dig("timestamp")
        response_date = response_timestamp ? Time.at(response_timestamp).utc.to_date : nil

        result = { date: response_date, timestamp: response_timestamp }

        requested_stats.each do |api_name, db_column|
          result[db_column] = stats_hash[api_name] || 0
        end

        result
      end
    end
  end
end
