module TornApi
  module User
    class PersonalStats < Base
      attr_reader :torn_id, :timestamp

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

      def initialize(api_key, torn_id, timestamp: nil)
        super(api_key)
        @torn_id = torn_id
        @timestamp = timestamp
      end

      def endpoint
        "v2/user/#{@torn_id}/personalstats"
      end

      def fetch
        stat_names = ::PersonalStatSnapshot.api_stat_names.join(",")
        params = { stat: stat_names }
        params[:timestamp] = timestamp if timestamp

        response = get(endpoint, params)

        if response["personalstats"].present?
          parse_personalstats(response["personalstats"])
        else
          raise InvalidKeyError, "Torn API authentication failed: #{response}"
        end
      end

      private

      def parse_personalstats(stats)
        # stats is an array of { "name" => "...", "value" => ..., "timestamp" => ... }
        stats_hash = stats.each_with_object({}) do |stat, hash|
          hash[stat["name"]] = stat["value"]
        end

        # Get timestamp from the first stat (they should all have the same timestamp)
        response_timestamp = stats.first&.dig("timestamp")

        result = { timestamp: response_timestamp }

        ::PersonalStatSnapshot::TRACKED_STATS.each do |api_name, db_column|
          result[db_column] = stats_hash[api_name]
        end

        PersonalStatSnapshot.new(**result)
      end
    end
  end
end
