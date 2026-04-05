module TornApi
  module User
    class Discord < Base
      DiscordData = Data.define(:discord_id, :user_id)

      attr_reader :lookup_id

      def initialize(api_key, lookup_id)
        super(api_key)
        @lookup_id = lookup_id
      end

      def fetch
        response = get("v2/user/#{lookup_id}/discord")
        discord = response["discord"]

        return nil unless discord && discord["user_id"]

        DiscordData.new(
          discord_id: discord["discord_id"],
          user_id: discord["user_id"]
        )
      rescue TornApi::NotFoundError
        nil
      end
    end
  end
end
