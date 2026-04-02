module Recon
  module TornApi
    class Profile < ::TornApi::Base
      ProfileData = Data.define(:age, :level, :property, :last_action_timestamp)

      attr_reader :player_id

      def initialize(api_key, player_id)
        super(api_key)
        @player_id = player_id
      end

      def fetch
        response = get("v2/user/#{player_id}/profile", {})
        profile = response["profile"] || response

        ProfileData.new(
          age: profile["age"],
          level: profile["level"],
          property: profile.dig("property", "name"),
          last_action_timestamp: profile.dig("last_action", "timestamp")
        )
      end
    end
  end
end
