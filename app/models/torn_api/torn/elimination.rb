module TornApi
  module Torn
    class Elimination < Base
      ENDPOINT = "v2/torn/elimination".freeze

      Team = Data.define(
        :torn_id,
        :name,
        :participants,
        :position,
        :tickets,
        :lives,
        :wins,
        :losses,
        :eliminated,
        :eliminated_at
      )

      def fetch
        response = get(ENDPOINT)
        teams = response["elimination"]
        raise ApiError, "No elimination data returned: #{response}" if teams.blank?

        parse(teams)
      end

      private

      def parse(collection)
        collection.map do |team|
          Team.new(
            team["id"],
            team["name"],
            team["participants"],
            team["position"],
            team["score"],
            team["lives"],
            team["wins"],
            team["losses"],
            team["eliminated"],
            team["eliminated_timestamp"]
          )
        end
      end
    end
  end
end
