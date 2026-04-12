module TornApi
  class Market < Base
    ENDPOINT = "v2/market".freeze

    def fetch
      response = get(ENDPOINT, { striptags: false, selections: "pointsmarket" })
      if response["pointsmarket"].present?
        response["pointsmarket"]
      else
        raise ApiError, "No market data returned: #{response}"
      end
    end
  end
end
