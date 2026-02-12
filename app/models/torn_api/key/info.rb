module TornApi
  module Key
    class Info < TornApi::Base
      AccessData = Data.define(
        :level,
        :type,
        :faction,
        :company
      )

      UserData = Data.define(
        :id,
        :faction_id,
        :company_id
      )

      InfoData = Data.define(
        :access,
        :user
      )

      def fetch
        data = get("v2/key/info")

        raise TornApi::InvalidKeyError if data["error"]

        info_data = data["info"]

        access = AccessData.new(
          level: info_data.dig("access", "level"),
          type: info_data.dig("access", "type"),
          faction: info_data.dig("access", "faction"),
          company: info_data.dig("access", "company")
        )

        user = UserData.new(
          id: info_data.dig("user", "id"),
          faction_id: info_data.dig("user", "faction_id"),
          company_id: info_data.dig("user", "company_id")
        )

        InfoData.new(
          access: access,
          user: user
        )
      end
    end
  end
end
