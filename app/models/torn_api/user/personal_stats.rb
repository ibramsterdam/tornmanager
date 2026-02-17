module TornApi
  module User
    class PersonalStats < Base
      attr_reader :torn_id, :timestamp, :stat_batch

      PersonalStatSnapshot = Data.define(
        :timestamp,
        :drugs_xanax,
        :drugs_cannabis,
        :other_refills_energy,
        :other_refills_nerve,
        :items_used_boosters,
        :items_used_stat_enhancers,
        :missions_contracts_total,
        :crimes_offenses_total,
        :other_activity_time,
        :networth_total,
        :attacking_networth_money_mugged
      )

      # @param api_key [String] API key
      # @param torn_id [Integer] User's Torn ID
      # @param timestamp [Integer, nil] Unix timestamp for historical data
      # @param stat_batch [Hash, nil] Specific stats to fetch (api_name => db_column), defaults to all
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
          raise InvalidKeyError, "Torn API authentication failed: #{response}"
        end
      end

      private

      def parse_personalstats(stats, requested_stats)
        # stats is an array of { "name" => "...", "value" => ..., "timestamp" => ... }
        # Note: API omits stats with value 0, so we default missing stats to 0
        stats_hash = stats.each_with_object({}) do |stat, hash|
          hash[stat["name"]] = stat["value"]
        end

        # Get timestamp from the first stat (they should all have the same timestamp)
        response_timestamp = stats.first&.dig("timestamp")

        # Build result with only the requested stats, defaulting missing to 0
        result = { timestamp: response_timestamp }

        requested_stats.each do |api_name, db_column|
          # Default to 0 if stat not in response (API omits stats with value 0)
          result[db_column] = stats_hash[api_name] || 0
        end

        result
      end
    end
  end
end
