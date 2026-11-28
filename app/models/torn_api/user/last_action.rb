module TornApi
  module User
    class LastAction < Base
      attr_reader :torn_id

      Result = Data.define(:torn_id, :name, :level, :last_action_at)

      def initialize(api_key, torn_id)
        super(api_key)
        @torn_id = torn_id
      end

      def endpoint
        "v2/user/#{torn_id}/profile"
      end

      def fetch
        profile = get(endpoint, { striptags: true, comment: "tmrecruiter" })["profile"]
        raise ApiError, "No profile returned for #{torn_id}" if profile.blank?

        timestamp = profile.dig("last_action", "timestamp")
        Result.new(
          torn_id: profile["id"] || torn_id,
          name: profile["name"],
          level: profile["level"],
          last_action_at: timestamp && Time.zone.at(timestamp)
        )
      end
    end
  end
end
