module TornApi
  module User
    class Profile < Base
      ProfileData = Data.define(
        :id,
        :name,
        :level,
        :image
      )

      def endpoint
        "v2/user/profile"
      end

      def fetch
        response = get(endpoint, { striptags: true })
        if response["profile"].present?
          parse_profile(response["profile"])
        else
          raise ApiError, "No profile data returned: #{response}"
        end
      end

      private

      def parse_profile(data)
        ProfileData.new(
          id: data["id"],
          name: data["name"],
          level: data["level"],
          image: data["image"]
        )
      end
    end
  end
end
