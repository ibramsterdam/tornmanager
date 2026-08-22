module TornApi
  module Torn
    class HofLeaderboard < Base
      ENDPOINT = "v2/torn/hof".freeze
      PAGE_SIZE = 100

      Row = Data.define(
        :torn_id,
        :name,
        :level,
        :value,
        :last_action
      )

      def initialize(api_key, offset: 0, limit: PAGE_SIZE)
        super(api_key)
        @offset = offset
        @limit = limit
      end

      def endpoint
        ENDPOINT
      end

      def fetch
        response = get(endpoint, { cat: "workstats", limit: @limit, offset: @offset, comment: "tmrecruiter" })
        parse(response["hof"] || [])
      end

      private

      def parse(collection)
        collection.map do |row|
          Row.new(
            torn_id: row["id"],
            name: row["username"],
            level: row["level"],
            value: row["value"],
            last_action: row["last_action"]
          )
        end
      end
    end
  end
end
