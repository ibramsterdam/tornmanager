require "net/http"
require "json"

module TornApi
  class InvalidKeyError < StandardError; end
  class ApiError < StandardError; end

  class Base
    DEFAULT_PARAMS = { comment: "tornmanager" }.freeze

    attr_reader :api_key

    def initialize(api_key)
      raise InvalidKeyError, "No API key provided" if api_key.blank?
      @api_key = api_key
    end

    def get(path, params = {})
      merged_params = DEFAULT_PARAMS.merge(params)
      uri = URI("https://api.torn.com/#{path}")
      uri.query = URI.encode_www_form(merged_params) if params.any?

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        req = Net::HTTP::Get.new(uri)
        req["accept"] = "application/json"
        req["Authorization"] = "ApiKey #{api_key}"
        resp = http.request(req)
        unless resp.code.to_i == 200
          raise ApiError, "Torn API request failed (HTTP #{resp.code})"
        end
        JSON.parse(resp.body)
      end
    end
  end
end
