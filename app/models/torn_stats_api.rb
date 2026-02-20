require "net/http"
require "json"

module TornStatsApi
  class ApiError < StandardError; end
  class RateLimitError < ApiError; end
  class InvalidKeyError < ApiError; end
  class NotFoundError < ApiError; end

  class Base
    BASE_URL = "https://www.tornstats.com"
    DEFAULT_READ_TIMEOUT = 15
    DEFAULT_OPEN_TIMEOUT = 5

    attr_reader :api_key

    def initialize(api_key)
      raise InvalidKeyError, "No TornStats API key provided" if api_key.blank?
      @api_key = api_key
    end

    def get(path)
      uri = URI("#{BASE_URL}/#{path}")

      Rails.logger.info("TornStatsAPI request: #{uri.path.gsub(api_key, '[REDACTED]')}")

      response = perform_request(uri)
      body = parse_response(response)

      Rails.logger.debug("TornStatsAPI success: #{uri.path.gsub(api_key, '[REDACTED]')}")

      body
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      Rails.logger.error("TornStatsAPI timeout: #{e.message}")
      raise ApiError, "TornStats API request timed out"
    rescue JSON::ParserError => e
      Rails.logger.error("TornStatsAPI JSON parse error: #{e.message}")
      raise ApiError, "Invalid JSON response from TornStats API"
    rescue Net::HTTPError, SocketError => e
      Rails.logger.error("TornStatsAPI network error: #{e.message}")
      raise ApiError, "Network error contacting TornStats: #{e.message}"
    end

    private

    def perform_request(uri)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true,
        read_timeout: DEFAULT_READ_TIMEOUT,
        open_timeout: DEFAULT_OPEN_TIMEOUT
      ) do |http|
        req = Net::HTTP::Get.new(uri)
        req["accept"] = "application/json"
        http.request(req)
      end
    end

    def parse_response(response)
      unless response.code.to_i == 200
        Rails.logger.error("HTTP #{response.code} from TornStats API: #{response.body[0..500]}")
        raise ApiError, "TornStats API request failed (HTTP #{response.code})"
      end

      JSON.parse(response.body)
    end
  end
end
