module TornApi
  module Faction
    class Members < Base
      attr_reader :torn_id
      Member = Data.define(
        :id,
        :name,
        :level,
        :days_in_faction,
        :last_action_status,
        :last_action_timestamp,
        :last_action_relative,
        :status_description,
        :status_details,
        :status_state,
        :status_color,
        :status_until,
        :revive_setting,
        :position,
        :is_revivable,
        :is_on_wall,
        :is_in_oc,
        :has_early_discharge
      )

      def initialize(api_key, torn_id)
        super(api_key)
        @torn_id = torn_id
      end

      def endpoint
        "v2/faction/#{@torn_id}/members"
      end

      def fetch
        response = get(endpoint, striptags: false)
        if response["members"].present?
          parse(response["members"])
        else
          raise InvalidKeyError, "Torn API authentication failed: #{response['error']&.dig('description')}"
        end
      end

      private

      def parse(members_array)
        members_array.map do |member|
          Member.new(
            member["id"],
            member["name"],
            member["level"],
            member["days_in_faction"],
            member.dig("last_action", "status"),
            member.dig("last_action", "timestamp"),
            member.dig("last_action", "relative"),
            member.dig("status", "description"),
            member.dig("status", "details"),
            member.dig("status", "state"),
            member.dig("status", "color"),
            member.dig("status", "until"),
            member["revive_setting"],
            member["position"],
            member["is_revivable"],
            member["is_on_wall"],
            member["is_in_oc"],
            member["has_early_discharge"]
          )
        end
      end
    end
  end
end
