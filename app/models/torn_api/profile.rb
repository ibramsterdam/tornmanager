module TornApi
  class Profile < Base
    ENDPOINT = "v2/user/basic".freeze

    def fetch
      response = get(ENDPOINT, striptags: false)
      if response["profile"].present?
        response["profile"]
      else
        raise InvalidKeyError, "Torn API authentication failed: #{response['error']&.dig('description')}"
      end
    end
  end
end
