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
        response = get("v2/user/#{player_id}", { striptags: true })

        ProfileData.new(
          age: response["age"],
          level: response["level"],
          property: response["property"],
          last_action_timestamp: response.dig("last_action", "timestamp")
        )
      end
    end
  end
end
