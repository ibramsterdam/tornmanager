module TornStatsApi
  class SpyFaction < Base
    SpyData = Data.define(
      :torn_id,
      :name,
      :level,
      :strength,
      :defense,
      :speed,
      :dexterity,
      :total,
      :spied_at
    )

    attr_reader :faction_id

    def initialize(api_key, faction_id:)
      super(api_key)
      @faction_id = faction_id
    end

    def fetch
      response = get("api/v2/#{api_key}/spy/faction/#{faction_id}")

      unless response["status"]
        message = response["message"] || "Unknown error"
        raise NotFoundError, "TornStats spy data not available: #{message}"
      end

      faction_data = response["faction"]
      unless faction_data && faction_data["members"]
        raise NotFoundError, "No faction member data in TornStats response"
      end

      parse_members(faction_data["members"])
    end

    private

    def parse_members(members_hash)
      spies = []

      members_hash.each do |torn_id, member_data|
        spy = member_data["spy"]

        if spy && spy["total"]
          spy_timestamp = spy["timestamp"]
          spied_at = spy_timestamp ? Time.at(spy_timestamp.to_i) : nil

          spies << SpyData.new(
            torn_id: torn_id.to_i,
            name: member_data["name"],
            level: member_data["level"],
            strength: spy["strength"]&.to_i,
            defense: spy["defense"]&.to_i,
            speed: spy["speed"]&.to_i,
            dexterity: spy["dexterity"]&.to_i,
            total: spy["total"]&.to_i,
            spied_at: spied_at
          )
        end
      end

      spies
    end
  end
end
