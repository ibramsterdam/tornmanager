module TornApi
  module User
    class Profile < Base
      ENDPOINT = "v2/user/basic".freeze

      ProfileData = Data.define(
        :id,
        :name,
        :level,
        :gender,
        :status
      )

      def fetch
        response = get(ENDPOINT, striptags: false)
        if response["profile"].present?
          parse_profile(response["profile"])
        else
          raise InvalidKeyError, "Torn API authentication failed: #{response}"
        end
      end

      private

      def parse_profile(data)
        ProfileData.new(
          id: data["id"],
          name: data["name"],
          level: data["level"],
          gender: data["gender"],
          status: data["status"]
        )
      end
    end
  end
end
