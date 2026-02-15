module TornApi
  module User
    class Basic < Base
      attr_reader :torn_id

      BasicData = Data.define(
        :id,
        :name,
        :level,
        :gender,
        :status
      )

      def initialize(api_key, torn_id = nil)
        super(api_key)
        @torn_id = torn_id
      end

      def endpoint
        if torn_id
          "v2/user/#{torn_id}/basic"
        else
          "v2/user/basic"
        end
      end

      def fetch
        response = get(endpoint, { striptags: true })
        if response["profile"].present?
          parse_profile(response["profile"])
        else
          raise InvalidKeyError, "Torn API authentication failed: #{response}"
        end
      end

      private

      def parse_profile(data)
        BasicData.new(
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
