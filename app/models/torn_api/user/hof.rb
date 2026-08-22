module TornApi
  module User
    class Hof < Base
      attr_reader :torn_id

      def initialize(api_key, torn_id)
        super(api_key)
        @torn_id = torn_id
      end

      def endpoint
        "v2/user/#{torn_id}/hof"
      end

      def fetch
        response = get(endpoint, { comment: "tmrecruiter" })
        hof = response["hof"] || {}
        stats = hof["working_stats"] || hof["workstats"] || hof["workingstats"]
        stats["value"] if stats.is_a?(Hash)
      end
    end
  end
end
