module Recon
  module TornApi
    class PersonalStats < ::TornApi::Base
      attr_reader :player_id, :stats, :timestamp

      def initialize(api_key, player_id, stats:, timestamp:)
        super(api_key)
        @player_id = player_id
        @stats = stats
        @timestamp = timestamp
      end

      def fetch
        response = get("v2/user/#{player_id}/personalstats", {
          stat: stats.join(","),
          timestamp: timestamp
        })

        parse(response["personalstats"] || [])
      end

      private

      def parse(stats_array)
        stats_array.each_with_object({}) do |stat, hash|
          hash[stat["name"]] = stat["value"]
        end
      end
    end
  end
end
