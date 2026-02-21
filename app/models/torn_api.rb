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
      start_time = Time.current
      api_params = params.is_a?(Hash) ? params : {}
      merged_params = DEFAULT_PARAMS.merge(api_params)
      uri = URI("#{BASE_URL}/#{path}")
      uri.query = URI.encode_www_form(merged_params)

      log_request(uri)

      response = perform_request(uri)
      body = parse_response(response)

      check_for_errors(body)

      response_time = ((Time.current - start_time) * 1000).to_i
      log_api_call(path, merged_params, "success", response_time, body["_metadata"])
      log_success(uri)

      # Track successful API call metrics
      if defined?(::Appsignal)
        ::Appsignal.add_distribution_value("torn_api.response_time", response_time)
        ::Appsignal.increment_counter("torn_api.requests", 1, { status: "success", endpoint: path.split("/").first })
      end

      body
    rescue InvalidKeyError, ApiError => e
      response_time = ((Time.current - start_time) * 1000).to_i
      log_api_call(path, merged_params, "error", response_time, nil, e.message)

      # Track API errors
      if defined?(::Appsignal)
        ::Appsignal.increment_counter("torn_api.requests", 1, { status: "error", endpoint: path.split("/").first, error_type: e.class.name })
      end

      raise
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      handle_timeout(uri, api_params, e, retries, start_time)
    rescue JSON::ParserError => e
      response_time = ((Time.current - start_time) * 1000).to_i
      log_api_call(path, merged_params, "error", response_time, nil, "JSON parse error: #{e.message}")
      Rails.logger.error("JSON parse error for #{uri}: #{e.message}")

      ::Appsignal.increment_counter("torn_api.requests", 1, { status: "error", endpoint: path.split("/").first, error_type: "JSONParseError" }) if defined?(::Appsignal)

      raise ApiError, "Invalid JSON response from Torn API"
    rescue Net::HTTPError, SocketError => e
      handle_network_error(uri, api_params, e, retries, start_time)
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
        ::Appsignal.increment_counter("torn_api.invalid_key", 1) if defined?(::Appsignal)
        raise InvalidKeyError, "Invalid API key"
      when 5
        ::Appsignal.increment_counter("torn_api.rate_limit", 1) if defined?(::Appsignal)
        raise RateLimitError, "Too many requests: #{error_msg}"
      when 6
        raise NotFoundError, "Incorrect ID: #{error_msg}"
      when 8
        raise ApiError, "IP block: #{error_msg}"
      when 9
        raise ApiError, "API disabled: #{error_msg}"
      when 10
        ::Appsignal.increment_counter("torn_api.invalid_key", 1) if defined?(::Appsignal)
        raise InvalidKeyError, "Key owner is in federal jail"
      when 13
        ::Appsignal.increment_counter("torn_api.rate_limit", 1) if defined?(::Appsignal)
        raise RateLimitError, "Key rate limit reached: #{error_msg}"
      else
        raise ApiError, "API error #{error_code}: #{error_msg}"
      end
    end

    def handle_timeout(uri, api_params, error, retries, start_time)
      if retries < MAX_RETRIES
        Rails.logger.warn("Timeout for #{uri}, retrying (#{retries + 1}/#{MAX_RETRIES}): #{error.message}")
        ::Appsignal.increment_counter("torn_api.retries", 1, { reason: "timeout" }) if defined?(::Appsignal)
        sleep(1 * (retries + 1))
        get(uri.path.sub(/^\//, ""), api_params, retries: retries + 1)
      else
        response_time = ((Time.current - start_time) * 1000).to_i
        log_api_call(uri.path.sub(/^\//, ""), api_params, "error", response_time, nil, "Timeout after #{MAX_RETRIES} retries")
        Rails.logger.error("Timeout for #{uri} after #{MAX_RETRIES} retries: #{error.message}")
        ::Appsignal.increment_counter("torn_api.requests", 1, { status: "error", error_type: "TimeoutError" }) if defined?(::Appsignal)
        raise TimeoutError, "Torn API request timed out after #{MAX_RETRIES} retries"
      end
    end

    def handle_network_error(uri, api_params, error, retries, start_time)
      if retries < MAX_RETRIES
        Rails.logger.warn("Network error for #{uri}, retrying (#{retries + 1}/#{MAX_RETRIES}): #{error.message}")
        ::Appsignal.increment_counter("torn_api.retries", 1, { reason: "network_error" }) if defined?(::Appsignal)
        sleep(1 * (retries + 1))
        get(uri.path.sub(/^\//, ""), api_params, retries: retries + 1)
      else
        response_time = ((Time.current - start_time) * 1000).to_i
        log_api_call(uri.path.sub(/^\//, ""), api_params, "error", response_time, nil, "Network error: #{error.message}")
        Rails.logger.error("Network error for #{uri} after #{MAX_RETRIES} retries: #{error.message}")
        ::Appsignal.increment_counter("torn_api.requests", 1, { status: "error", error_type: "NetworkError" }) if defined?(::Appsignal)
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

    def log_api_call(endpoint, params, status, response_time, metadata, error_message = nil)
      target_user = resolve_api_key_owner

      unless target_user
        Rails.logger.debug("log_api_call skipped: no user found for api_key=#{api_key[0..5]}...")
        return
      end

      ApiCall.create!(
        user: target_user,
        api_key: api_key,
        endpoint: endpoint,
        selections: params.except(:comment, :striptags).to_json,
        response_time: response_time,
        status: status,
        error_message: error_message,
        torn_api_timestamp: metadata&.dig("timestamp")
      )
    rescue => e
      Rails.logger.error("Failed to log API call: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
    end

    def resolve_api_key_owner
      @resolved_user ||= begin
        # Try to find user by API key
        found = ::User.find_by(api_key: api_key)
        return found if found

        # Fall back to owner if this is the owner key
        if api_key == OwnerCredentials.api_key
          ::User.find_by(torn_id: 2728237)
        end
      end
    end
  end
end
