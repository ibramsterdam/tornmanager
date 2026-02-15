require "net/http"
require "json"

module TornApi
  class InvalidKeyError < StandardError; end
  class ApiError < StandardError; end
  class RateLimitError < ApiError; end
  class NotFoundError < ApiError; end
  class TimeoutError < ApiError; end

  class Base
    DEFAULT_PARAMS = { comment: "tmanager" }.freeze
    BASE_URL = "https://api.torn.com"
    DEFAULT_READ_TIMEOUT = 10
    DEFAULT_OPEN_TIMEOUT = 5
    MAX_RETRIES = 2

    attr_reader :api_key

    def initialize(api_key)
      raise InvalidKeyError, "No API key provided" if api_key.blank?
      @api_key = api_key
    end

    def get(path, params = {}, retries: 0)
      merged_params = DEFAULT_PARAMS.merge(params)
      uri = URI("#{BASE_URL}/#{path}")
      uri.query = URI.encode_www_form(merged_params)

      log_request(uri)

      response = perform_request(uri)
      body = parse_response(response)

      check_for_errors(body)

      log_success(uri)
      body
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      handle_timeout(uri, e, retries)
    rescue JSON::ParserError => e
      Rails.logger.error("JSON parse error for #{uri}: #{e.message}")
      raise ApiError, "Invalid JSON response from Torn API"
    rescue Net::HTTPError, SocketError => e
      handle_network_error(uri, e, retries)
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
        req["Authorization"] = "ApiKey #{api_key}"
        http.request(req)
      end
    end

    def parse_response(response)
      unless response.code.to_i == 200
        Rails.logger.error("HTTP #{response.code} from Torn API: #{response.body[0..500]}")
        raise ApiError, "Torn API request failed (HTTP #{response.code})"
      end

      JSON.parse(response.body)
    end

    def check_for_errors(body)
      return unless body["error"]
      handle_api_error(body["error"])
    end

    def handle_api_error(error)
      error_code = error["code"]
      error_msg = error["error"]

      case error_code
      when 2
        raise InvalidKeyError, "Invalid API key"
      when 5
        raise RateLimitError, "Too many requests: #{error_msg}"
      when 6
        raise NotFoundError, "Incorrect ID: #{error_msg}"
      when 8
        raise ApiError, "IP block: #{error_msg}"
      when 9
        raise ApiError, "API disabled: #{error_msg}"
      when 10
        raise InvalidKeyError, "Key owner is in federal jail"
      when 13
        raise RateLimitError, "Key rate limit reached: #{error_msg}"
      else
        raise ApiError, "API error #{error_code}: #{error_msg}"
      end
    end

    def handle_timeout(uri, error, retries)
      if retries < MAX_RETRIES
        Rails.logger.warn("Timeout for #{uri}, retrying (#{retries + 1}/#{MAX_RETRIES}): #{error.message}")
        sleep(1 * (retries + 1)) # Exponential backoff: 1s, 2s
        get(uri.path.sub("#{BASE_URL}/", ""), parse_query(uri.query), retries: retries + 1)
      else
        Rails.logger.error("Timeout for #{uri} after #{MAX_RETRIES} retries: #{error.message}")
        raise TimeoutError, "Torn API request timed out after #{MAX_RETRIES} retries"
      end
    end

    def handle_network_error(uri, error, retries)
      if retries < MAX_RETRIES
        Rails.logger.warn("Network error for #{uri}, retrying (#{retries + 1}/#{MAX_RETRIES}): #{error.message}")
        sleep(1 * (retries + 1))
        get(uri.path.sub("#{BASE_URL}/", ""), parse_query(uri.query), retries: retries + 1)
      else
        Rails.logger.error("Network error for #{uri} after #{MAX_RETRIES} retries: #{error.message}")
        raise ApiError, "Network error: #{error.message}"
      end
    end

    def parse_query(query_string)
      return {} unless query_string
      URI.decode_www_form(query_string).to_h.symbolize_keys
    end

    def log_request(uri)
      Rails.logger.info("TornAPI request: #{uri.path}?#{uri.query&.gsub(/key=[^&]+/, 'key=[REDACTED]')}")
    end

    def log_success(uri)
      Rails.logger.debug("TornAPI success: #{uri.path}")
    end
  end
end
